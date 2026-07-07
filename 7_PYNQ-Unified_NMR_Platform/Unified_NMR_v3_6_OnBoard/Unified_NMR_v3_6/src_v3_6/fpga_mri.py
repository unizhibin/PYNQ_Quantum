# ----------------------------------------------------------------------------------
# Authors: Yitian Chen, Zhibin Zhao, Yichao Peng
# Affiliation: Institut für Intelligente Sensorik und Theoretische Elektrotechnik (IIS), University of Stuttgart, Germany
# Release date: 2026.07.01
# Software release: Unified NMR / MRI Control Software v3.6
# ----------------------------------------------------------------------------------

# revision.01 from 25.08.2025
#---- debug: offset = offset+2048, stepsize = -stepsize
#---- search token: # bbtt25082025
# from pynq import Overlay
# from pynq import allocate
import numpy as np
import matplotlib.pyplot as plt # as mp
import json 
import os 



## ---- Address Map ---- ##

C_SEQUENCE_GENERATOR_EN            = 0x00

# configuration (write) registers
# set the number of sections
C_SET_NR_SECTIONS                  = 0x04
# write section selector
C_WRITE_SEL_SECTION                = 0x08
# set section type
C_SET_SECTION_TYPE                 = 0x0C
# set section duration (delay)
C_SET_DELAY                        = 0x10
# set section multiplexer
C_SET_MUX                          = 0x14
# set repetition start pointer
C_SET_START_REPEAT_POINTER         = 0x18
# set repetition end pointer
C_SET_END_REPEAT_POINTER           = 0x1C
# set cycle repetition count
C_SET_CYCLE_REPETITION_NUMBER      = 0x20
# set experiment repetition count
C_SET_EXPERIMENT_REPETITION_NUMBER = 0x24
# channel 0 – set phase
C_SET_PHASE_CH0                    = 0x28
# channel 0 – set frequency
C_SET_FREQUENCY_CH0                = 0x2C
# channel 1 – set phase
C_SET_PHASE_CH1                    = 0x30
# channel 1 – set frequency
C_SET_FREQUENCY_CH1                = 0x34
# DDS reset (active low)
C_SET_RESETN_DDS                   = 0x38

# channel busy flag
C_GET_BUSY                         = 0x3C
# data ready flag
C_GET_DATA_READY                   = 0x40
# number of DDS channels
C_GET_NR_DDS_CH                    = 0x44
# memory depth
C_GET_MEM_DEPTH                    = 0x48
# number of activity
C_GET_NR_ACTIVITY                  = 0x4C

# set LED output
C_SET_LED                         = 0x50
# set gradient X
C_SET_GRADIENT_X                  = 0x54
# set gradient Y
C_SET_GRADIENT_Y                  = 0x58
# set gradient Z
C_SET_GRADIENT_Z                  = 0x5C
# set gradient X reference
C_SET_GRADIENT_X_REF              = 0x60
# set gradient Y reference
C_SET_GRADIENT_Y_REF              = 0x64
# set gradient Z reference
C_SET_GRADIENT_Z_REF              = 0x68
# set gradient sweep
C_SET_GRADIENT_SWEEP              = 0x6C

# set gradient X sweep step
C_SET_GRADIENT_X_SWEEP_STEP       = 0x70
# set gradient Y sweep step
C_SET_GRADIENT_Y_SWEEP_STEP       = 0x74
# set gradient Z sweep step
C_SET_GRADIENT_Z_SWEEP_STEP       = 0x78

# set gradient X sweep offset
C_SET_GRADIENT_X_SWEEP_OFFSET     = 0x7C
# set gradient Y sweep offset
C_SET_GRADIENT_Y_SWEEP_OFFSET     = 0x80
# set gradient Z sweep offset
C_SET_GRADIENT_Z_SWEEP_OFFSET     = 0x84

C_COMMIT_SECTION                  = 0x88
C_READBACK_SECTION                = 0x8C
C_READBACK_WORD                   = 0x90
C_READBACK_DATA                   = 0x94

EXPECTED_NR_ACTIVITY              = 18

SECTION_WORDS = (
    'section_type',
    'delay',
    'mux',
    'phase_ch0',
    'frequency_ch0',
    'phase_ch1',
    'frequency_ch1',
    'rstn',
    'x_gradient',
    'y_gradient',
    'z_gradient',
    'x_ref',
    'y_ref',
    'z_ref',
    'x_sweep_offset',
    'y_sweep_offset',
    'z_sweep_offset',
    'gradient_sweep_flag',
)
SECTION_WORD_INDEX = {name: index for index, name in enumerate(SECTION_WORDS)}


# class MRI_Section:
#     def __init__(self, ip,section_id, section_type, delay, mux, phase_ch0, frequency_ch0, phase_ch1, frequency_ch1,
#                  rstn, x_gradient, y_gradient, z_gradient, x_ref, y_ref, z_ref, x_sweep_offset, y_sweep_offset,
#                    z_sweep_offset, x_sweep_step_size, y_sweep_step_size, z_sweep_step_size, gradient_sweep_flag):
#         self.section_id = int(section_id)
#         self.section_type = int(section_type)
#         self.delay = int(delay)
#         self.mux = int(mux)
#         self.phase_ch0 = int(phase_ch0)
#         self.frequency_ch0 = int(frequency_ch0)
#         self.phase_ch1 = int(phase_ch1)
#         self.frequency_ch1 = int(frequency_ch1)
#         self.rstn = int(rstn)
#         self.x_gradient = int(x_gradient)
#         self.y_gradient = int(y_gradient)
#         self.z_gradient = int(z_gradient)
#         self.x_ref = int(x_ref)
#         self.y_ref = int(y_ref)
#         self.z_ref = int(z_ref)
#         self.x_sweep_offset = int(x_sweep_offset)
#         self.y_sweep_offset = int(y_sweep_offset)
#         self.z_sweep_offset = int(z_sweep_offset)
#         self.x_sweep_step_size = int(x_sweep_step_size)
#         self.y_sweep_step_size = int(y_sweep_step_size)
#         self.z_sweep_step_size = int(z_sweep_step_size)
#         self.gradient_sweep_flag = int(gradient_sweep_flag)
#         self.ip = ip


""" 
The section configuration is a Numpy array of two columns and multiple rows
The columns are the attributes name as strings, and the values are the attributes values
ch0 is the tx channel, ch1 is the rx channel for the mux and for the frequency 
[*] The delay value is in microseconds
"""
class MRI_Section:
    def __init__(self, ip, SectionConfig):
        self.t = 100 # for pulsegen with 250 Mhz  # At 100Mhz, 100 clks = 1 us 
        # self.f = 2.5 *17179869 //4  # 1Mhz, for 32 bits phase width in DDS 
        # self.f = 2.5 *17179869 //4 *2 # 1Mhz, for 32 bits phase width in DDS
        # self.f = 10737418 *2 # for 250 Mhz DDS, verified
        # self.f = 100 * 214492 *2 # 346DC for 0.00999830126762390e6 Hz, 100 MHz DDS
        self.f = 100 * 171798 * 2 # 29F16 for 0.0099999597296118736, 250 MHz DDS
        self.p = 536870912 / 180 * 4 # for pi phase 
        # self.p = 10000000
        # self.p = 2 * 11930465 * 8 /8 * 2.5
        self.ip = ip
        self.SectionConfig = SectionConfig
        self.SectionReadout = None 
        self.read_SectionConfig()

    def read_SectionConfig(self):
        # make sure all section attributes are in integer format, where self.SectionConfig is a numpy array
        # for i in range(len(self.SectionConfig)):
        #     self.SectionConfig[i][1] = int(self.SectionConfig[i][1])
        # check if there is a "sectio_id" element in the array 
        if "section_id" in self.SectionConfig[:, 0]:
            self.section_id = self.SectionConfig[self.SectionConfig[:, 0] == 'section_id'][0][1]
        else: self.section_id = None 
        if "section_type" in self.SectionConfig[:, 0]:
            self.section_type = self.SectionConfig[self.SectionConfig[:, 0] == 'section_type'][0][1]
        else: self.section_type = None
        if "delay" in self.SectionConfig[:, 0]:
            self.delay = self.SectionConfig[self.SectionConfig[:, 0] == 'delay'][0][1]
        else: self.delay = None
        if "mux" in self.SectionConfig[:, 0]:
            self.mux = self.SectionConfig[self.SectionConfig[:, 0] == 'mux'][0][1]
        else: self.mux = None
        if "phase_ch0" in self.SectionConfig[:, 0]:
            self.phase_ch0 = self.SectionConfig[self.SectionConfig[:, 0] == 'phase_ch0'][0][1]
        else: self.phase_ch0 = None
        if "frequency_ch0" in self.SectionConfig[:, 0]:
            self.frequency_ch0 = self.SectionConfig[self.SectionConfig[:, 0] == 'frequency_ch0'][0][1]
        else: self.frequency_ch0 = None
        if "phase_ch1" in self.SectionConfig[:, 0]:
            self.phase_ch1 = self.SectionConfig[self.SectionConfig[:, 0] == 'phase_ch1'][0][1]
        else: self.phase_ch1 = None
        if "frequency_ch1" in self.SectionConfig[:, 0]:
            self.frequency_ch1 = self.SectionConfig[self.SectionConfig[:, 0] == 'frequency_ch1'][0][1]
        else: self.frequency_ch1 = None
        if "rstn" in self.SectionConfig[:, 0]:
            self.rstn = self.SectionConfig[self.SectionConfig[:, 0] == 'rstn'][0][1]
        else: self.rstn = None
        if "x_gradient" in self.SectionConfig[:, 0]:
            self.x_gradient = self.SectionConfig[self.SectionConfig[:, 0] == 'x_gradient'][0][1]
        else: self.x_gradient = None
        if "y_gradient" in self.SectionConfig[:, 0]:
            self.y_gradient = self.SectionConfig[self.SectionConfig[:, 0] == 'y_gradient'][0][1]
        else: self.y_gradient = None
        if "z_gradient" in self.SectionConfig[:, 0]:
            self.z_gradient = self.SectionConfig[self.SectionConfig[:, 0] == 'z_gradient'][0][1]
        else: self.z_gradient = None
        if "x_ref" in self.SectionConfig[:, 0]:
            self.x_ref = self.SectionConfig[self.SectionConfig[:, 0] == 'x_ref'][0][1]
        else: self.x_ref = None
        if "y_ref" in self.SectionConfig[:, 0]:
            self.y_ref = self.SectionConfig[self.SectionConfig[:, 0] == 'y_ref'][0][1]
        else: self.y_ref = None
        if "z_ref" in self.SectionConfig[:, 0]:
            self.z_ref = self.SectionConfig[self.SectionConfig[:, 0] == 'z_ref'][0][1]
        else: self.z_ref = None
        if "gradient_sweep_flag" in self.SectionConfig[:, 0]:
            self.gradient_sweep_flag = self.SectionConfig[self.SectionConfig[:, 0] == 'gradient_sweep_flag'][0][1]
        else: self.gradient_sweep_flag = None
        if "x_sweep_step_size" in self.SectionConfig[:, 0]:
            self.x_sweep_step_size = self.SectionConfig[self.SectionConfig[:, 0] == 'x_sweep_step_size'][0][1]
        else: self.x_sweep_step_size = None
        if "y_sweep_step_size" in self.SectionConfig[:, 0]:
            self.y_sweep_step_size = self.SectionConfig[self.SectionConfig[:, 0] == 'y_sweep_step_size'][0][1]
        else: self.y_sweep_step_size = None
        if "z_sweep_step_size" in self.SectionConfig[:, 0]:
            self.z_sweep_step_size = self.SectionConfig[self.SectionConfig[:, 0] == 'z_sweep_step_size'][0][1]
        else: self.z_sweep_step_size = None
        if "x_sweep_offset" in self.SectionConfig[:, 0]:
            self.x_sweep_offset = self.SectionConfig[self.SectionConfig[:, 0] == 'x_sweep_offset'][0][1]
        else: self.x_sweep_offset = None
        if "y_sweep_offset" in self.SectionConfig[:, 0]:
            self.y_sweep_offset = self.SectionConfig[self.SectionConfig[:, 0] == 'y_sweep_offset'][0][1]
        else: self.y_sweep_offset = None
        if "z_sweep_offset" in self.SectionConfig[:, 0]:
            self.z_sweep_offset = self.SectionConfig[self.SectionConfig[:, 0] == 'z_sweep_offset'][0][1]
        else: self.z_sweep_offset = None
        

    # TODO: add assert method to make sure the grad values are in the right range

    def WriteReg(self):
        # write the section ID
        if self.section_id is not None:
            self.ip.write(C_WRITE_SEL_SECTION, int(self.section_id))
        if self.section_type is not None:
            self.ip.write(C_SET_SECTION_TYPE, int(self.section_type))
        if self.delay is not None:
            self.ip.write(C_SET_DELAY, int( float(self.delay)* self.t) )
        if self.mux is not None:
            self.ip.write(C_SET_MUX, int(self.mux))
        if self.phase_ch0 is not None:
            self.ip.write(C_SET_PHASE_CH0, int( float(self.phase_ch0) * self.p ))
        if self.frequency_ch0 is not None:
            self.ip.write(C_SET_FREQUENCY_CH0, int(float(self.frequency_ch0) * self.f))
        if self.phase_ch1 is not None:
            self.ip.write(C_SET_PHASE_CH1, int( float(self.phase_ch1)* self.p ))
        if self.frequency_ch1 is not None:
            self.ip.write(C_SET_FREQUENCY_CH1, int(float(self.frequency_ch1) * self.f))
        if self.rstn is not None:
            self.ip.write(C_SET_RESETN_DDS, int(self.rstn))
        if self.x_gradient is not None:
            self.ip.write(C_SET_GRADIENT_X, int(self.x_gradient))
        if self.y_gradient is not None:
            self.ip.write(C_SET_GRADIENT_Y, int(self.y_gradient))
        if self.z_gradient is not None:
            self.ip.write(C_SET_GRADIENT_Z, int(self.z_gradient))
        if self.x_ref is not None:
            self.ip.write(C_SET_GRADIENT_X_REF, int(self.x_ref))
        if self.y_ref is not None:
            self.ip.write(C_SET_GRADIENT_Y_REF, int(self.y_ref))
        if self.z_ref is not None:
            self.ip.write(C_SET_GRADIENT_Z_REF, int(self.z_ref))
        if self.gradient_sweep_flag is not None:
            self.ip.write(C_SET_GRADIENT_SWEEP, int(self.gradient_sweep_flag))
        # bbtt25082025
        #--------------------------------------------------------------------------
        # if self.x_sweep_step_size is not None:
        #     self.ip.write(C_SET_GRADIENT_X_SWEEP_STEP, int(self.x_sweep_step_size))
        # if self.y_sweep_step_size is not None:
        #     self.ip.write(C_SET_GRADIENT_Y_SWEEP_STEP, int(self.y_sweep_step_size))
        # if self.z_sweep_step_size is not None:
        #     self.ip.write(C_SET_GRADIENT_Z_SWEEP_STEP, int(self.z_sweep_step_size))
        # bbtt25082025    
        if self.x_sweep_offset is not None:
            self.ip.write(C_SET_GRADIENT_X_SWEEP_OFFSET, int(self.x_sweep_offset))
        if self.y_sweep_offset is not None:
            self.ip.write(C_SET_GRADIENT_Y_SWEEP_OFFSET, int(self.y_sweep_offset))
        if self.z_sweep_offset is not None:
            self.ip.write(C_SET_GRADIENT_Z_SWEEP_OFFSET, int(self.z_sweep_offset))
        # Commit the staged scalar fields into the section RAM.
        if self.section_id is not None:
            self.ip.write(C_COMMIT_SECTION, int(self.section_id))
        ##---------------------------------------------------------------------------
        # if self.x_sweep_offset is not None:
        #     self.ip.write(C_SET_GRADIENT_X_SWEEP_OFFSET, int(self.x_sweep_offset) - 2048)
        # if self.y_sweep_offset is not None:
        #     self.ip.write(C_SET_GRADIENT_Y_SWEEP_OFFSET, int(self.y_sweep_offset) - 2048)
        # if self.z_sweep_offset is not None:
        #     self.ip.write(C_SET_GRADIENT_Z_SWEEP_OFFSET, int(self.z_sweep_offset) - 2048)
        ##----------------------------------------------------------------------------

    def ReadReg(self):
        # create a np array to store all possible values to the related register
        Section_Readout = np.zeros((0, 2)) 
        # read the address map and store the values in the array
        Section_Readout = np.vstack([Section_Readout, ['section_id', self.ip.read(C_WRITE_SEL_SECTION)]])
        Section_Readout = np.vstack([Section_Readout, ['section_type', self.ip.read(C_SET_SECTION_TYPE)]])
        Section_Readout = np.vstack([Section_Readout, ['delay', self.ip.read(C_SET_DELAY)]])
        Section_Readout = np.vstack([Section_Readout, ['mux', self.ip.read(C_SET_MUX)]])
        Section_Readout = np.vstack([Section_Readout, ['phase_ch0', self.ip.read(C_SET_PHASE_CH0)]])
        Section_Readout = np.vstack([Section_Readout, ['frequency_ch0', self.ip.read(C_SET_FREQUENCY_CH0)]])
        Section_Readout = np.vstack([Section_Readout, ['phase_ch1', self.ip.read(C_SET_PHASE_CH1)]])
        Section_Readout = np.vstack([Section_Readout, ['frequency_ch1', self.ip.read(C_SET_FREQUENCY_CH1)]])
        Section_Readout = np.vstack([Section_Readout, ['rstn', self.ip.read(C_SET_RESETN_DDS)]])
        Section_Readout = np.vstack([Section_Readout, ['x_gradient', self.ip.read(C_SET_GRADIENT_X)]])
        Section_Readout = np.vstack([Section_Readout, ['y_gradient', self.ip.read(C_SET_GRADIENT_Y)]])
        Section_Readout = np.vstack([Section_Readout, ['z_gradient', self.ip.read(C_SET_GRADIENT_Z)]])
        Section_Readout = np.vstack([Section_Readout, ['x_ref', self.ip.read(C_SET_GRADIENT_X_REF)]])
        Section_Readout = np.vstack([Section_Readout, ['y_ref', self.ip.read(C_SET_GRADIENT_Y_REF)]])
        Section_Readout = np.vstack([Section_Readout, ['z_ref', self.ip.read(C_SET_GRADIENT_Z_REF)]])
        Section_Readout = np.vstack([Section_Readout, ['gradient_sweep_flag', self.ip.read(C_SET_GRADIENT_SWEEP)]])
        Section_Readout = np.vstack([Section_Readout, ['x_sweep_step_size', self.ip.read(C_SET_GRADIENT_X_SWEEP_STEP)]])
        Section_Readout = np.vstack([Section_Readout, ['y_sweep_step_size', self.ip.read(C_SET_GRADIENT_Y_SWEEP_STEP)]])
        Section_Readout = np.vstack([Section_Readout, ['z_sweep_step_size', self.ip.read(C_SET_GRADIENT_Z_SWEEP_STEP)]])
        Section_Readout = np.vstack([Section_Readout, ['x_sweep_offset', self.ip.read(C_SET_GRADIENT_X_SWEEP_OFFSET)]])
        Section_Readout = np.vstack([Section_Readout, ['y_sweep_offset', self.ip.read(C_SET_GRADIENT_Y_SWEEP_OFFSET)]])
        Section_Readout = np.vstack([Section_Readout, ['z_sweep_offset', self.ip.read(C_SET_GRADIENT_Z_SWEEP_OFFSET)]])
        # convert the array to int
        self.SectionReadout = Section_Readout
        return Section_Readout 



def parse_json(json_file):
    with open(json_file, 'r') as f:
        data = json.load(f)
    # the json file has two major groups: "ExpConfig" and "SectionConfig"
    # the "ExpConfig" group has the following keys: "nr_sections", "start_repeat_pointer", "end_repeat_pointer" ... 
    # The "SectionConfig" group has subgroups for each section, with the following keys: "section_id", "section_type"....
    ExpConfig_dict = data['ExpConfig']
    Sections_dict = data['SectionConfig']    
    ExpConfig = np.zeros((0, 2))
    # get the keys of the ExpConfig group and its values into the array 
    for key in ExpConfig_dict.keys():
        ExpConfig = np.vstack([ExpConfig, [key, ExpConfig_dict[key]]])
    SecList = []
    for key in Sections_dict.keys():
        # get the keys of the SectionConfig group and its values into the array 
        SectionConfig = np.zeros((0, 2))
        Section = Sections_dict[key]
        for subkey in Sections_dict[key].keys():
            SectionConfig = np.vstack([SectionConfig, [subkey, Section[subkey]]])
        # create a new section object
        SecList.append(SectionConfig)
    # print("ExpConfig: ", ExpConfig)
    # print("Sections: ", SecList)
    return ExpConfig, SecList 


def _array_value(config_array, key, default=None):
    rows = config_array[config_array[:, 0] == key]
    if rows.size:
        return rows[0][1]
    return default


def _as_int(value, field_name):
    try:
        return int(float(value))
    except (TypeError, ValueError) as exc:
        raise ValueError(f"{field_name} must be an integer-compatible value, got {value!r}.") from exc
    

class MRI_Sequence:
    def __init__(self, ip, ExpConfig, SecList):
        self.ip = ip
        self.ExpConfig = ExpConfig
        self.SecList = SecList
        self.Sections = [] 
        self.load_summary = {}
        self._validated = False

    def read_ExpConfig(self):
        # read the experiment configuration
        if "nr_sections" in self.ExpConfig[:, 0]:
            self.nr_sections = self.ExpConfig[self.ExpConfig[:, 0] == 'nr_sections'][0][1]
        else: self.nr_sections = None
        if "start_repeat_pointer" in self.ExpConfig[:, 0]:
            self.start_repeat_pointer = self.ExpConfig[self.ExpConfig[:, 0] == 'start_repeat_pointer'][0][1]
        else: self.start_repeat_pointer = None
        if "end_repeat_pointer" in self.ExpConfig[:, 0]:
            self.end_repeat_pointer = self.ExpConfig[self.ExpConfig[:, 0] == 'end_repeat_pointer'][0][1]
        else: self.end_repeat_pointer = None
        if "cycle_repetition_number" in self.ExpConfig[:, 0]:
            self.cycle_repetition_number = self.ExpConfig[self.ExpConfig[:, 0] == 'cycle_repetition_number'][0][1]
        else: self.cycle_repetition_number = None
        if "experiment_repetition_number" in self.ExpConfig[:, 0]:
            self.experiment_repetition_number = self.ExpConfig[self.ExpConfig[:, 0] == 'experiment_repetition_number'][0][1]
        else: self.experiment_repetition_number = None
        if "gradient_x_sweep_step" in self.ExpConfig[:, 0]:
            self.gradient_x_sweep_step = self.ExpConfig[self.ExpConfig[:, 0] == 'gradient_x_sweep_step'][0][1]
        else: self.gradient_x_sweep_step = None
        if "gradient_y_sweep_step" in self.ExpConfig[:, 0]:
            self.gradient_y_sweep_step = self.ExpConfig[self.ExpConfig[:, 0] == 'gradient_y_sweep_step'][0][1]
        else: self.gradient_y_sweep_step = None
        if "gradient_z_sweep_step" in self.ExpConfig[:, 0]:
            self.gradient_z_sweep_step = self.ExpConfig[self.ExpConfig[:, 0] == 'gradient_z_sweep_step'][0][1]
        else: self.gradient_z_sweep_step = None

    def _section_ids(self):
        ids = []
        for index, section_config in enumerate(self.SecList):
            sid = _array_value(section_config, "section_id")
            if sid is None:
                raise ValueError(f"SectionConfig entry {index} is missing 'section_id'.")
            ids.append(_as_int(sid, f"section_id for section entry {index}"))
        return ids

    def _read_ip_register_optional(self, addr):
        if self.ip is None:
            return None
        try:
            value = int(self.ip.read(addr))
        except Exception:
            return None
        # Older dummy or partially initialized MMIO objects often read as 0 here.
        return value if value > 0 else None

    def validate_config(self, *, check_hardware=True):
        if not hasattr(self, "nr_sections"):
            self.read_ExpConfig()

        if self.nr_sections is None:
            raise ValueError("ExpConfig is missing 'nr_sections'.")

        nr_sections = _as_int(self.nr_sections, "nr_sections")
        ids = self._section_ids()
        unique_ids = set(ids)

        if len(ids) != len(unique_ids):
            duplicates = sorted(sid for sid in unique_ids if ids.count(sid) > 1)
            raise ValueError(f"Duplicate section_id values in SectionConfig: {duplicates}")

        expected_ids = set(range(nr_sections))
        missing_ids = sorted(expected_ids - unique_ids)
        extra_ids = sorted(unique_ids - expected_ids)
        if missing_ids or extra_ids:
            raise ValueError(
                "Section IDs must be contiguous from 0 to nr_sections - 1. "
                f"Missing: {missing_ids}; outside range: {extra_ids}."
            )

        if len(self.SecList) != nr_sections:
            raise ValueError(
                f"ExpConfig declares nr_sections={nr_sections}, "
                f"but SectionConfig contains {len(self.SecList)} entries."
            )

        start = _as_int(self.start_repeat_pointer, "start_repeat_pointer")
        end = _as_int(self.end_repeat_pointer, "end_repeat_pointer")
        if not (0 <= start <= end < nr_sections):
            raise ValueError(
                "Repeat pointers must satisfy 0 <= start_repeat_pointer <= "
                f"end_repeat_pointer < nr_sections; got start={start}, "
                f"end={end}, nr_sections={nr_sections}."
            )

        mem_depth = None
        nr_activity = None
        if check_hardware:
            mem_depth = self._read_ip_register_optional(C_GET_MEM_DEPTH)
            nr_activity = self._read_ip_register_optional(C_GET_NR_ACTIVITY)

            if mem_depth is not None and nr_sections > mem_depth:
                raise ValueError(
                    f"Sequence needs {nr_sections} sections, but pulse-generator "
                    f"IP reports mem_depth={mem_depth}."
                )
            if nr_activity is not None and nr_activity != EXPECTED_NR_ACTIVITY:
                raise ValueError(
                    f"Software expects {EXPECTED_NR_ACTIVITY} activity words per section, "
                    f"but pulse-generator IP reports nr_activity={nr_activity}."
                )

        self.load_summary = {
            "nr_sections": nr_sections,
            "section_ids": ids,
            "start_repeat_pointer": start,
            "end_repeat_pointer": end,
            "mem_depth": mem_depth,
            "nr_activity": nr_activity,
        }
        self._validated = True
        return self.load_summary

    def write_ExpConfig(self):
        self.validate_config(check_hardware=True)
        # write the experiment configuration to the register
        if self.nr_sections is not None:
            self.ip.write(C_SET_NR_SECTIONS, _as_int(self.nr_sections, "nr_sections"))
        if self.start_repeat_pointer is not None:
            self.ip.write(C_SET_START_REPEAT_POINTER, _as_int(self.start_repeat_pointer, "start_repeat_pointer"))
        if self.end_repeat_pointer is not None:
            self.ip.write(C_SET_END_REPEAT_POINTER, _as_int(self.end_repeat_pointer, "end_repeat_pointer"))
        if self.cycle_repetition_number is not None:
            self.ip.write(C_SET_CYCLE_REPETITION_NUMBER, _as_int(self.cycle_repetition_number, "cycle_repetition_number"))
        if self.experiment_repetition_number is not None:
            self.ip.write(C_SET_EXPERIMENT_REPETITION_NUMBER, _as_int(self.experiment_repetition_number, "experiment_repetition_number"))
        #bbtt25082025 
        # ---------------------------------------------------------------------------
        if self.gradient_x_sweep_step is not None:
            self.ip.write(C_SET_GRADIENT_X_SWEEP_STEP, _as_int(self.gradient_x_sweep_step, "gradient_x_sweep_step"))
        if self.gradient_y_sweep_step is not None:
            self.ip.write(C_SET_GRADIENT_Y_SWEEP_STEP, _as_int(self.gradient_y_sweep_step, "gradient_y_sweep_step"))
        if self.gradient_z_sweep_step is not None:
            self.ip.write(C_SET_GRADIENT_Z_SWEEP_STEP, _as_int(self.gradient_z_sweep_step, "gradient_z_sweep_step"))
        # if self.gradient_x_sweep_step is not None:
        #     self.ip.write(C_SET_GRADIENT_X_SWEEP_STEP, -int(self.gradient_x_sweep_step))
        # if self.gradient_y_sweep_step is not None:
        #     self.ip.write(C_SET_GRADIENT_Y_SWEEP_STEP, -int(self.gradient_y_sweep_step))
        # if self.gradient_z_sweep_step is not None:
        #     self.ip.write(C_SET_GRADIENT_Z_SWEEP_STEP, -int(self.gradient_z_sweep_step))
    def write_one_Section(self, section):
        if not self._validated:
            self.validate_config(check_hardware=False)

        wanted = _as_int(section, "section")
        for section_config in self.SecList:
            sid = _as_int(_array_value(section_config, "section_id"), "section_id")
            if sid != wanted:
                continue
            Section = MRI_Section(self.ip, section_config)
            Section.WriteReg()
            self.Sections = [s for s in self.Sections if _as_int(s.section_id, "section_id") != wanted]
            self.Sections.append(Section)
            return Section
        raise ValueError(f"Section ID not found: {wanted}")

    def write_all_Sections(self):
        if not self._validated:
            self.validate_config(check_hardware=False)
        # write all sections to the register
        ordered_sections = sorted(
            self.SecList,
            key=lambda section_config: _as_int(
                _array_value(section_config, "section_id"),
                "section_id",
            ),
        )
        for section_config in ordered_sections:
            self.write_one_Section(_array_value(section_config, "section_id"))
        
    def start_sequence(self):
        self.ip.write(C_SEQUENCE_GENERATOR_EN, 0)
        self.ip.write(C_SEQUENCE_GENERATOR_EN, 1)
        # print(f"start sequence: {self.ip.read(C_GET_BUSY)}")

    def stop_sequence(self): 
        # print(f"stop sequence: {self.ip.read(C_GET_BUSY)}")
        self.ip.write(C_SEQUENCE_GENERATOR_EN, 0)


    def visualize_sequence(
        self,
        *,
        dpi: int = 150,
        save_path: str | None = None,
        show: bool = True,
    ):
        """
        Render the pulse-sequence with proper PE “squares” and fixed gradient refs.
        Assumes np & plt are already imported, and read_ExpConfig()
        has been called to populate start/end pointers and cycle_repetition_number.
        """
        # ensure ExpConfig is loaded
        self.read_ExpConfig()

        if not self.SecList:
            raise RuntimeError("SecList is empty – parse your JSON first.")

        # ---- build timing + flags + gradients + refs -------------------
        t0, dur = [], []
        lbl, tx_mask, rx_mask = [], [], []
        gx, gy, gz, mux = [], [], [], []
        sweep_flag = []
        x_ref_list, y_ref_list, z_ref_list = [], [], []

        cursor = 0.0
        for sec in self.SecList:
            def _get(key, default=0):
                rows = sec[sec[:,0] == key]
                return float(rows[0][1]) if rows.size else default

            δ    = _get("delay")
            st   = int(_get("section_type", -1))
            sid  = int(_get("section_id",    -1))
            offx = int(_get("x_gradient",    0))
            offy = int(_get("y_gradient",    0))
            offz = int(_get("z_gradient",    0))
            sw   = int(_get("gradient_sweep_flag", 0))

            refx = int(_get("x_ref"))
            refy = int(_get("y_ref"))
            refz = int(_get("z_ref"))

            # timing
            t0.append(cursor)
            dur.append(δ)
            cursor += δ

            # section masks
            lbl.append(sid)
            tx_mask.append(st == 0)
            rx_mask.append(st == 1)

            # gradients & mux
            gx.append(offx)
            gy.append(offy)
            gz.append(offz)
            mux.append(int(_get("mux")))

            # sweep flag & refs
            sweep_flag.append(sw)
            x_ref_list.append(refx)
            y_ref_list.append(refy)
            z_ref_list.append(refz)

        edges = np.concatenate(([0], np.cumsum(dur)))
        # since all sections share the same refs, just grab the first
        x_ref = x_ref_list[0]
        y_ref = y_ref_list[0]
        z_ref = z_ref_list[0]

        # ---- figure & axes (7 rows) ------------------------------------
        fig, ax = plt.subplots(
            7, 1, figsize=(20, 10), sharex=True,
            gridspec_kw=dict(height_ratios=[0.4, 0.6, 0.6, 0.6, 1.0, 0.6, 0.6])
        )
        titles = ["Repeat","RF TX","RF RX","Gx","Gy (PE)","Gz","MUX"]

        # common µs-ticks & section dividers
        xt = edges
        xl = [f"{int(x)}" for x in xt]
        for a in ax:
            a.grid(True, axis="x", linestyle=":", linewidth=0.4)
            for x in xt:
                a.axvline(x, linestyle="--", color="k", alpha=0.35, linewidth=0.4)
            a.set_xticks(xt);      a.set_xticklabels(xl, rotation=90, fontsize=7)
            a.tick_params(axis="x", labelbottom=True, pad=2)
            a.tick_params(axis="y", labelleft=True)

        # ---- row 0: Repeat pointers -----------------------------------
        ar = ax[0]
        ar.set_ylim(0,1); ar.set_yticks([])
        ar.set_title("Repeat", loc="left", fontsize=9, pad=2)
        for ptr in ("start_repeat_pointer","end_repeat_pointer"):
            val = getattr(self, ptr, None)
            if val is not None and int(val) in lbl:
                idx = lbl.index(int(val))
                ar.axvline(edges[idx], color="yellow", linestyle="--", linewidth= 4 )

        # ---- rows 1–2: RF TX / RX --------------------------------------
        for i, (mask, col) in enumerate(zip([tx_mask, rx_mask],
                                           ["tab:red","tab:green"]), start=1):
            rax = ax[i]
            for s,d,ok,sid in zip(t0,dur,mask,lbl):
                if not ok: continue
                rax.broken_barh([(s,d)], (0,1), facecolors=col)
                rax.text(s + d/2, 0.7, f"{d:.0f} µs",
                         ha="center", va="center", color="white", fontsize=7)
                rax.text(s + d/2, 0.3, f"id {sid}",
                         ha="center", va="center", color="white", fontsize=7)
            rax.set_ylim(0,1); rax.set_yticks([])
            rax.set_title(titles[i], loc="left", fontsize=9, pad=2)

        # ---- row 3: Gx -------------------------------------------------
        agx = ax[3]
        agx.step(edges[:-1], gx, where="post", color="tab:blue", linewidth=2)
        agx.set_ylim(-300, 4095)
        agx.axhline(x_ref, linestyle="--", color="gray", linewidth= 2)
        # add annotation on the x_ref line at the end of the line
        agx.annotate(f"X Ref: {x_ref}", xy=(edges[-1], x_ref), xytext=(edges[-1]+10, x_ref+600),
                   # arrowprops=dict(arrowstyle="->", lw=1.5, color="gray"),
                    fontsize=10, color="gray", ha="left", va="center")
        # add legend for the x_ref line
        # agx.legend(["Gx", "X Ref"], loc="upper right", fontsize=10, frameon=False)
        agx.set_ylabel("Gx", rotation=0, labelpad=15)
        agx.set_title(titles[3], loc="left", fontsize=9, pad=2)

        # ---- row 4: Gy (PE) squares -----------------------------------
          # ---- row 4: Gy (PE) with correct two‐trace behavior --------------
        agy = ax[4]
        cycs = int(self.cycle_repetition_number)
        step = float(self.gradient_y_sweep_step)
        # for every section, draw two horizontal blue lines
        for s, d, off, sw in zip(t0, dur, gy, sweep_flag):
            if d <= 0:
                continue
            y0 = off
            # only when sweep_flag==2 do we lift the top trace
            y1 = off + cycs * step if sw == 2 else off
            # bottom trace
            agy.plot([s, s + d], [y0, y0], color="tab:blue", linewidth=2)
            # top trace
            agy.plot([s, s + d], [y1, y1], color="tab:blue", linewidth=2)
        agy.set_ylim(-300, 4095)
        agy.axhline(y_ref, linestyle="--", color="gray", linewidth=2)
        # add annotation on the y_ref line at the end of the line
        agy.annotate(f"Y Ref: {y_ref}", xy=(edges[-1], y_ref), xytext=(edges[-1]+10, y_ref+600),
                    # arrowprops=dict(arrowstyle="->", lw=1.5, color="gray"),
                    fontsize=10, color="gray", ha="left", va="center")
        # add legend for the y_ref line
        # agy.legend(["Gy", "Y Ref"], loc="upper right", fontsize=7, frameon=False)
        agy.set_ylabel("Gy", rotation=0, labelpad=15)
        agy.set_title("Gy (PE)", loc="left", fontsize=9, pad=2)

        # ---- row 5: Gz -------------------------------------------------
        agz = ax[5]
        agz.step(edges[:-1], gz, where="post", color="tab:blue", linewidth=2)
        agz.set_ylim(-300, 4095)
        agz.axhline(z_ref, linestyle="--", color="gray", linewidth=2)
        # add annotation on the z_ref line at the end of the line
        agz.annotate(f"Z Ref: {z_ref}", xy=(edges[-1], z_ref), xytext=(edges[-1]+10, z_ref+600),
                    # arrowprops=dict(arrowstyle="->", lw=1.5, color="gray"),
                    fontsize=10, color="gray", ha="left", va="center")
        # add legend for the z_ref line
        # agz.legend(["Gz", "Z Ref"], loc="upper right", fontsize=7, frameon=False)
        agz.set_ylabel("Gz", rotation=0, labelpad=15)
        agz.set_title(titles[5], loc="left", fontsize=9, pad=2)

        # ---- row 6: MUX ------------------------------------------------
        am = ax[6]
        am.step(edges[:-1], mux, where="post", color="tab:blue")
        am.set_ylabel("MUX", rotation=0, labelpad=20)
        am.set_yticks([0,1]); am.set_yticklabels(["TX","RX"])
        am.set_xlabel("time [µs]")
        am.set_title(titles[6], loc="left", fontsize=9, pad=2)

        # ---- finalize -------------------------------------------------
        fig.tight_layout()
        if save_path:
            fig.savefig(save_path, dpi=dpi, bbox_inches="tight")
        if show:
            plt.show()
        plt.close(fig)


## sweep_flag = [0, off]  [1, x] [2, y] [3, z] 

#---- Test Field ----#
# Sec0 = MRI_Section(None, np.array([ ['section_id', 0], ['section_type', 1], ['delay', 2] ])  )
# print(Sec0.section_id)
# print(Sec0.section_type)                                                      
# print(Sec0.delay)
# print(Sec0.mux)

# test = np.zeros((0, 2))
# # add a row to the array
# test = np.vstack([test, ['section_id', 0]])
# print(test)

# print(os.getcwd())
# parse_json( os.getcwd()+ "\\MRI_Dev_Ver0\\CSE_sequence\\"+ "CSE_advanced.json")

# class dummy_ip:
#     def write(self, addr, value):
#         print("Writing to address: ", addr, " value: ", value)

# test_ip = dummy_ip() 
# ExpConfig, SecList = parse_json( os.getcwd()+ "\\MRI_Dev_Ver0\\CSE_sequence\\"+ "CSE_advanced.json")
# CSE_advanced = MRI_Sequence(test_ip, ExpConfig, SecList)
# CSE_advanced.read_ExpConfig()
# CSE_advanced.write_ExpConfig()
# CSE_advanced.write_all_Sections()
# CSE_advanced.visualize_sequence(save_path= os.getcwd()+ "\\MRI_Dev_Ver0\\CSE_sequence\\"+"CSE_advanced.jpg")  # + pops up a window
