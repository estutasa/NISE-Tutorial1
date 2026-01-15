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

    def __process_events(self,events : EventsPublisher.ScEvents):

        # checking history  
        if not hasattr(self, "_sc_state"):
            self._sc_state = {}

        now = time.monotonic() # creates timestamp in seconds
        release_timeout= 0.25  # in sec, after this time without events -> green again

        sc_ids : List[int] = [] # list of seen IDs
        for e in events:
            sc_id = e["sc_id"]
            e_id = e["id"]
            val = e["value"]

            # if sc_id == 1 and e_id == EventsPublisher.EVENT_ID_PROX:
            #     print(f"prox = {val}")

            if sc_id == 1 and e_id == EventsPublisher.EVENT_ID_FORCE1:
                print(f"force1 = {val}")

            if sc_id == 1 and e_id == EventsPublisher.EVENT_ID_FORCE2:
                print(f"force2 = {val}")

            if sc_id == 1 and e_id == EventsPublisher.EVENT_ID_FORCE3:
                print(f"force3 = {val}")

            if sc_id not in self._sc_state: # if cell id not seen yet, initialize 
                self._sc_state[sc_id] = ("green", now) # set to initial green

            # cell colour logic: 
            if e_id == EventsPublisher.EVENT_ID_PROX:  # proximity -> red
                # only set red if it isn't already blue (force overrides)
                current_color, _ = self._sc_state[sc_id]
                if current_color != "blue":
                    self._sc_state[sc_id] = ("red", now)
                else:
                    # still update the timestamp so it doesn't go green too early
                    self._sc_state[sc_id] = ("blue", now)

                if sc_id not in sc_ids:
                    sc_ids.append(sc_id)

            # force -> blue (override)
            elif e_id in (
                EventsPublisher.EVENT_ID_FORCE1,
                EventsPublisher.EVENT_ID_FORCE2,
                EventsPublisher.EVENT_ID_FORCE3
            ):
                self._sc_state[sc_id] = ("blue", now)

                if sc_id not in sc_ids:
                    sc_ids.append(sc_id)

        # timeout logic: set to green if no events for a while
        for sc_id in list(self._sc_state.keys()):
            current_color, last_ts = self._sc_state[sc_id]
            if (now - last_ts) > release_timeout: # if timeout exceeded revert to initial state
                self._sc_state[sc_id] = ("green", last_ts)

    # map colour names into LED values
        sc_colors : LedFeedbackEvents.ScColorList = []
        for sc_id, (color_name, _) in self._sc_state.items():
            sc_color = (sc_id, COLOR_VAL_MAP.get(color_name, COLOR_VAL_MAP.get("white")))
            sc_colors.append(sc_color)

        with self.__mutex:
            self.__sc_colors = copy.deepcopy(sc_colors)


    def __update(self):
        ## synchronous update loop, 50 Hz
        with self.__mutex:
            sc_colors = copy.deepcopy(self.__sc_colors)

        for sc_color in sc_colors:
            sc_id = sc_color[0]
            color = sc_color[1]
            self.__led_ctrl.set_led_color_val(color,sc_id)  # has a delay of 10 ms
            

            
    # ??????????????????????????????????????????????????????????????????

    def __run(self):
        self.logger.debug("Started Thread.")
        while not self.__stop_event.is_set():
            self.__update()
            time.sleep(20e-3) # 50 Hz

        self.logger.debug("Exit Thread.")
        self.__stop_event.clear()


    
