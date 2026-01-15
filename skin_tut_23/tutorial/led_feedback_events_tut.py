#!/usr/bin/python3


import copy
import logging
import threading
import time
from typing import Callable, List, Tuple

from scn.ctrl.handler.led_control import COLOR_VAL_MAP
from scn.hwi.hwi import HardwareInterface as Hwi
from scn.ctrl.handler import LedControl
from scn.sc.events_publisher import EventsPublisher

class LedFeedbackEvents:
    ScColor = Tuple[int,int]    # sc_id, color
    ScColorList = List[ScColor]

    @property
    def logger(self):
        return logging.getLogger(f"{__name__}.{self.__class__.__name__}")


    def __init__(self, hwi : Hwi, events_pub : EventsPublisher, led_ctrl : LedControl):
        self.__hwi = hwi
        self.__events_pub = events_pub
        self.__led_ctrl = led_ctrl
        self.__started = False
        self.__thread = None
        self.__stop_event = threading.Event()
        self.__mutex = threading.Lock()
        self.__sc_colors : LedFeedbackEvents.ScColorList = []

        events_pub.add_callback(self.__process_events)


    def __del__(self):
        self.logger.debug("Destroy.")
        if self.__started:
            self.stop()



    def start(self):
        if self.__started:
            self.logger.error("Already started.")
            return
        
        self.__thread = threading.Thread(target=self.__run)
        self.__thread.start()
        self.__started = True

    def stop(self):
        if not self.__started:
            self.logger.error("Already stopped.")
            return
        self.logger.debug("Stopping Thread.")
        self.__stop_event.set()
        self.__thread.join()
        self.__started = False


    def isStarted(self) -> bool:
        return self.__started

    
    def isStopped(self) -> bool:
        return not self.__started

   # ??????????????????????????????????????????????????????????????????
    #   Change the led color according to touch events
    #       green   = no contact
    #       red     = proximity event
    #       blue    = force event (overrides proximity event)
    # 
    #   If you want you can implement also visual feedback for
    #       vibrational or acceleration events.
    # ??????????????????????????????????????????????????????????????????

    def __process_events(self, events : EventsPublisher.ScEvents):
        new_sc_colors_dict = {}

        # thresholds based on experimental tuning
        PROX_THRESHOLD = 0.09
        FORCE_THRESHOLD = 0.04

        for e in events:
            sc_id = e["sc_id"]
            e_id = e["id"]
            val = e["value"]

            if sc_id not in new_sc_colors_dict:
                new_sc_colors_dict[sc_id] = COLOR_VAL_MAP.get("green")

            # red (proximity)
            if e_id == EventsPublisher.EVENT_ID_PROX:
                if val > PROX_THRESHOLD:
                    # blue (force) has higher priority than red (proximity)
                    if new_sc_colors_dict[sc_id] != COLOR_VAL_MAP.get("blue"):
                        new_sc_colors_dict[sc_id] = COLOR_VAL_MAP.get("red")
                else:
                    # reset to green if proximity value drops below threshold
                    new_sc_colors_dict[sc_id] = COLOR_VAL_MAP.get("green")

            # blue (force)
            force_ids = [EventsPublisher.EVENT_ID_FORCE1, 
                         EventsPublisher.EVENT_ID_FORCE2, 
                         EventsPublisher.EVENT_ID_FORCE3]
            
            if e_id in force_ids:
                if val > FORCE_THRESHOLD:
                    # overwrite any existing color with blue due to contact
                    new_sc_colors_dict[sc_id] = COLOR_VAL_MAP.get("blue")

        sc_colors : LedFeedbackEvents.ScColorList = []
        for sid, color_val in new_sc_colors_dict.items():
            sc_colors.append((sid, color_val))

        with self.__mutex:
            self.__sc_colors = copy.deepcopy(sc_colors)

    def __update(self):
        ## synchronous update loop running at 50 Hz
        with self.__mutex:
            sc_colors = copy.deepcopy(self.__sc_colors)

        for sc_color in sc_colors:
            sc_id = sc_color[0]
            color = sc_color[1]
            self.__led_ctrl.set_led_color_val(color, sc_id)
            
    # ??????????????????????????????????????????????????????????????????

    def __run(self):
        self.logger.debug("Started Thread.")
        while not self.__stop_event.is_set():
            self.__update()
            time.sleep(20e-3) # 50 Hz

        self.logger.debug("Exit Thread.")
        self.__stop_event.clear()