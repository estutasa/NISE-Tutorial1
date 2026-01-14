#!/usr/bin/python3


import logging
import threading
import time
from typing import Callable, List, Tuple

from scn.ctrl.handler.led_control import COLOR_VAL_MAP
from scn.sc.pkt.data import data_tuple_to_data1200
from scn.sc.data_publisher import DataPublisher
from scn.hwi.hwi import HardwareInterface as Hwi
from scn.ctrl.handler import LedControl

class LedFeedback:


    @property
    def logger(self):
        return logging.getLogger(f"{__name__}.{self.__class__.__name__}")


    def __init__(self, hwi : Hwi, data_pub : DataPublisher, led_ctrl : LedControl):
        self.__hwi = hwi
        self.__data_pub = data_pub
        self.__led_ctrl = led_ctrl
        self.__started = False
        self.__thread = None
        self.__stop_event = threading.Event()


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


    def __update(self):
        sc_data_list = self.__data_pub.sc_data()    

        for sc_data in sc_data_list:
            d = data_tuple_to_data1200(sc_data)
            sc_id = d["sc_id"]
            prox = d["prox"]
            force = d["force"]
            acc = d["acc"]
            temp = d["temp"]

            color = COLOR_VAL_MAP.get("white")

            # ??????????????????????????????????????????????????????????????????
            #   Change the led color according to touch events
            #       green   = no contact
            #       red     = proximity event
            #       blue    = force event (overrides proximity event)
            # 
            #   If you want you can implement also visual feedback for
            #       vibrational or acceleration events.
            # ??????????????????????????????????????????????????????????????????
            force_val = max(force) # there are 3 force values, but need to use one threshold --> take max measurement 
            
            # print(f"prox={prox:.4f}, force={force_val:.4f}") # print tio help get threshold values

            force_th = 0.01
            prox_th = 0.065

            if force_val > force_th:
                color = COLOR_VAL_MAP.get("blue")
            elif prox > prox_th:
                color = COLOR_VAL_MAP.get("red")
            else:
                color = COLOR_VAL_MAP.get("green")

            # ??????????????????????????????????????????????????????????????????

            self.__led_ctrl.set_led_color_val(color,sc_id)


    def __run(self):
        self.logger.debug("Started Thread.")
        while not self.__stop_event.is_set():
            self.__update()
            time.sleep(20e-3) # 50 Hz

        self.logger.debug("Exit Thread.")
        self.__stop_event.clear()


    
