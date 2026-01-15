#!/usr/bin/python3


import logging
import sys
from typing import List
from scn.sc.pkt.data import data_tuple_to_data1200
from scn.ctrl.handler import NeighListManager,UdrControl,CfControl,IdControl,SensControl,LedControl,EventsControl
from scn.icommand_handler import ICommandHandler
from scn.hwi.hwi import HardwareInterface as Hwi

from scn.sc.data_publisher import DataPublisher
from scn.sc.events_publisher import EventsPublisher

import scn.sc.pkt
import scn.ctrl.pkt

from scn.icommand_handler import ICommandHandler,descr_entry

from scn.core import mask, print_hex_block



from tutorial.led_feedback_events_tut import LedFeedbackEvents


# def print_packet(data : bytes):
#     print(f"data: len = {len(data)}")
#     print_hex_block(data)


# def print_sc_data(data : DataPublisher.ScData):
#     id = data[0]
#     vals = data[1]
#     d = data_tuple_to_data1200(data)
#     if id == 1:
#         # print(f"prox = {vals[0]}")
#         # print(f"fc  = [{vals[1]}, {vals[2]}, {vals[3]}]")
#         # print(f"fc1  = {vals[1]}")
#         # print(f"fc2  = {vals[2]}")
#         # print(f"fc3  = {vals[3]}")
#         # print(f"acc x  = {vals[4]}")
#         # print(f"acc y  = {vals[5]}")
#         # print(f"acc z  = {vals[6]}")
#         # print(f"temp  = {vals[7]}")
#         # print(d)
#         pass


# def print_sc_events(events : EventsPublisher.ScEvents):
#     for e in events:
#         sc_id = e["sc_id"]
#         e_id = e["id"]
#         val = e["value"]

#         # print(e)

#         # if sc_id == 1 and e_id == EventsPublisher.EVENT_ID_PROX:
#         #     print(f"prox = {val}")

#         if sc_id == 1 and e_id == EventsPublisher.EVENT_ID_FORCE1:
#             print(f"force1 = {val}")

#         if sc_id == 1 and e_id == EventsPublisher.EVENT_ID_FORCE2:
#             print(f"force2 = {val}")

#         if sc_id == 1 and e_id == EventsPublisher.EVENT_ID_FORCE3:
#             print(f"force3 = {val}")



def print_neighs(sc_neighs : NeighListManager.ScNeighborsList):
    print(sc_neighs)


if __name__ == '__main__':
    print("Test")

    logging.basicConfig(
        format='%(asctime)s,%(msecs)03d %(levelname)-8s [%(pathname)s:%(lineno)d] %(message)s',
        datefmt='%Y-%m-%d:%H:%M:%S',
        level=logging.CRITICAL
    )


    hwi = Hwi(Hwi.DefaultConfig())

    hwi.open()
    hwi.ctrl().reader().start()
    hwi.data().reader().start()

    # hwi.ctrl().reader().add_callback(print_packet)
    # hwi.data().reader().add_callback(print_packet)



    data_pub = DataPublisher(hwi)
    # data_pub.add_callback(print_sc_data)


    events_pub = EventsPublisher(hwi)
    # events_pub.add_callback(print_sc_events)



    handlers : List[ICommandHandler] = []

    neigh_list_manager = NeighListManager(hwi)
    neigh_list_manager.add_callback(print_neighs)


    led_ctrl = LedControl(hwi)


    handlers += [neigh_list_manager]
    handlers += [IdControl(hwi)]
    handlers += [SensControl(hwi)]
    handlers += [CfControl(hwi)]
    handlers += [UdrControl(hwi)]
    handlers += [led_ctrl]
    handlers += [EventsControl(hwi)]


    led_feedback_tut = LedFeedbackEvents(hwi,events_pub,led_ctrl)
    # led_feedback_tut.start()

    while(True):
        try:
            cmd = input()
            cmd_parts = cmd.split()
            cmd_len = len(cmd_parts)

            if(cmd == "q"):
                break

            if(cmd == "c"):
                data_pub.reset()
                hwi.connect()
                continue

            if(cmd == "d"):
                hwi.disconnect()
                continue

            if(cmd == "tut on"):
                led_feedback_tut.start()
                continue

            if(cmd == "tut off"):
                led_feedback_tut.stop()
                continue

            if cmd == "h":
                print()
                print("."*80)
                
                descr = str() \
                    + descr_entry("c",     "Connect to the skin.",30) \
                    + descr_entry("d",     "Disconnect the skin.",30) \
                    + descr_entry("q",     "Quit/Exit the app.",30) \
                    + descr_entry("tut on",     "Start tutorial thread.",30) \
                    + descr_entry("tut off",    "Stop tutorial thread.",30)
                print(descr)

                for h in handlers:
                    print(h.commandDescription())
                print("."*80)
                continue


            cmd_handled = False
            for h in handlers:
                if h.handleCommand(cmd):
                    cmd_handled = True
                    break

            if cmd_handled:
                continue


            print(f"Invalid cmd: '{cmd}'")

        except KeyboardInterrupt:
            break

    if led_feedback_tut.isStarted():
        led_feedback_tut.stop()

    hwi.close()
    

    sys.exit(0)
