#!/usr/bin/python3

from typing import Dict, List, Tuple, TypedDict
from scn.core import mask,intx_to_int
from scn.sc.pkt.tools import get_id



# Value layout for Data1200
#   0: prox
#   1: force1
#   2: force2
#   3: force3
#   4: acc_x
#   5: acc_y
#   6: acc_z
#   7: temp

SENS_NAME_VAL_IND_MAP : Dict[str,int] = {
    "prox"      : 0,
    "force1"    : 1,
    "force2"    : 2,
    "force3"    : 3,
    "acc_x"     : 4,
    "acc_y"     : 5,
    "acc_z"     : 6,
    "temp"      : 7,
}

class Data1200(TypedDict):
    sc_id:          int                         # skin cell ID
    prox:           float                       # proximity value, range: [0,1.0]
    force:          Tuple[float,float,float]    # force values, FC1, FC2, FC3, range: [0,1.0]
    acc:            Tuple[float,float,float]    # acceleration in g, x,y,z    
    temp:           float                       # temp in degrees Celsius

class Data(TypedDict):
    sc_id:          int                         # skin cell ID
    values:         List[float]                 # sensor values    



def get_data_prox_raw(pkt : bytes) -> int:
    m7 = mask(7)
    m2 = mask(2)

    v = 0
    v |= (pkt[3] << 9) & (m7 << 9)
    v |= (pkt[4] << 2) & (m7 << 2)
    v |= (pkt[10] >> 3) & m2

    return v

def get_data_force_raw(pkt : bytes, ind : int) -> int:
    m7 = mask(7)
    m5 = mask(5)

    v = 0
    v |= (pkt[11+ind*2] << 5) & (m7 << 5)
    v |= pkt[12+ind*2] & m5

    return v


def get_data_force_1_raw(pkt : bytes) -> int:
    return get_data_force_raw(pkt,0)

def get_data_force_2_raw(pkt : bytes) -> int:
    return get_data_force_raw(pkt,1)

def get_data_force_3_raw(pkt : bytes) -> int:
    return get_data_force_raw(pkt,2)




# x: 0, y: 1, z: 2
def get_data_acc_raw(pkt : bytes, ind : int) -> int:
    m7 = mask(7)
    m3 = mask(3)

    off = ind
    # remap: exchange x <> y
    if ind == 0:
        off = 1
    elif ind == 1:
        off = 0

    v = 0
    v |= (pkt[5+off] << 3) & (m7 << 3)
    v |= pkt[8+off] & m3

    if ind == 0:
        return intx_to_int(v,10)

    return -intx_to_int(v,10)


def get_data_acc_x_raw(pkt : bytes) -> int:
    return get_data_acc_raw(pkt,0)

def get_data_acc_y_raw(pkt : bytes) -> int:
    return get_data_acc_raw(pkt,1)

def get_data_acc_z_raw(pkt : bytes) -> int:
    return get_data_acc_raw(pkt,2)


def get_data_temp_raw(pkt : bytes) -> int:
    m4 = mask(4)

    v = 0
    v |= (pkt[8] << 1) & (m4 << 4)
    v |= (pkt[9] >> 3) & m4

    return intx_to_int(v,8)



def data_conv_to_prox(raw : int) -> float:
    return (raw)/0x10000    # isn't 0xFFFF highest value?

def data_conv_to_force(raw : int) -> float:
    return (raw)/1024

def data_conv_to_acc(raw : int) -> float:
    return (raw*2)/512

def data_conv_to_temp(raw : int) -> float:
    return (raw*0.5) + 24


def get_data_raw_values(pkt : bytes) -> List[int]:
    func = [
        get_data_prox_raw,
        get_data_force_1_raw,
        get_data_force_2_raw,
        get_data_force_3_raw,
        get_data_acc_x_raw,
        get_data_acc_y_raw,
        get_data_acc_z_raw,
        get_data_temp_raw
    ]
    val = []
    for f in func:
        val.append(f(pkt))
    return val

def get_data_values(pkt : bytes) -> List[float]:
    func = [
        data_conv_to_prox,
        data_conv_to_force,
        data_conv_to_force,
        data_conv_to_force,
        data_conv_to_acc,
        data_conv_to_acc,
        data_conv_to_acc,
        data_conv_to_temp
    ]
    raw = get_data_raw_values(pkt)
    val = []
    for ind,f in enumerate(func):
        val.append(f(raw[ind]))
    return val


def get_data_raw(pkt : bytes) -> Tuple[int,List[int]]:
    id = get_id(pkt)
    val = get_data_raw_values(pkt)
    return (id,val)


def get_data(pkt : bytes) -> Tuple[int,List[float]]:
    id = get_id(pkt)
    val = get_data_values(pkt)
    return (id,val)


def data_tuple_to_data(data : Tuple[int,List[float]]) -> Data:
    sc_id = data[0]
    values = data[1]
    return Data(sc_id=sc_id,values=values)


def data_tuple_to_data1200(data : Tuple[int,List[float]]) -> Data1200:
    sc_id = data[0]
    values = data[1]
    return Data1200(
        sc_id =sc_id,
        prox    = values[0],
        force   = (values[1],values[2],values[3]),
        acc     = (values[4],values[5],values[6]),
        temp = values[7])
