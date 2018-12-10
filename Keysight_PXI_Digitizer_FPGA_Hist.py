#!/usr/bin/env python
import sys
sys.path.append('C:\Program Files (x86)\Keysight\SD1\Libraries\Python')

from BaseDriver import LabberDriver, Error, IdError
import keysightSD1

import numpy as np
import math
import os


class Driver(LabberDriver):
    """ This class implements the Keysight PXI digitizer"""

    def performOpen(self, options={}):
        """Perform the operation of opening the instrument connection"""
        # number of demod blocks in the FPGA
        self.num_of_demods = 1
        self.demod_sample_size = 100

        # set time step and resolution
        self.nBit = 16
        self.bitRange = float(2**(self.nBit - 1) - 1)
        # timeout
        self.timeout_ms = int(1000 * self.dComCfg['Timeout'])
        # get PXI chassis
        self.chassis = int(self.dComCfg.get('PXI chassis', 1))
        # create AWG instance
        self.dig = keysightSD1.SD_AIN()
        AWGPart = self.dig.getProductNameBySlot(
            self.chassis, int(self.comCfg.address))
        self.log('Serial:', self.dig.getSerialNumberBySlot(
            self.chassis, int(self.comCfg.address)))
        if not isinstance(AWGPart, str):
            raise Error('Unit not available')
        # check that model is supported
        dOptionCfg = self.dInstrCfg['options']
        for validId, validName in zip(dOptionCfg['model_id'], dOptionCfg['model_str']):
            if AWGPart.find(validId) >= 0:
                # id found, stop searching
                break
        else:
            # loop fell through, raise ID error
            raise IdError(AWGPart, dOptionCfg['model_id'])
        # set model
        self.setModel(validName)
        # sampling rate and number of channles is set by model
        if validName in ('M3102', 'M3302'):
            # 500 MHz models
            self.dt = 2E-9
            self.nCh = 4
        else:
            # assume 100 MHz for all other models
            self.dt = 10E-9
            self.nCh = 4
        # create list of sampled data
        self.lTrace = [np.array([])] * self.nCh
        self.dig.openWithSlot(AWGPart, self.chassis, int(self.comCfg.address))
        # get hardware version - changes numbering of channels
        hw_version = self.dig.getHardwareVersion()
        if hw_version >= 4:
            # KEYSIGHT - channel numbers start with 1
            self.ch_index_zero = 1
        else:
            # SIGNADYNE - channel numbers start with 0
            self.ch_index_zero = 0
        self.log('HW:', hw_version)

        self.fpga_config = self.getValue('FPGA Hardware')

        if self.fpga_config == 'FPGA QB package (alpha)':
            Bitstream = os.path.join(os.path.dirname(__file__), 'firmware_debug_test_2018-12-10T07_34_18.sbp')

        if (self.dig.FPGAload(Bitstream)) < 0:
            raise Error('FPGA not loaded, check FPGA version...')

        for n in range(self.num_of_demods):
            LO_freq = self.getValue('LO freq ' + str(n + 1))
            self.setFPGALOfreq(LO_freq)

        self.setFPGATrigger()

        for name in ['Analyze Mode', 'Stream', 'I Bin Width', 'Q Bin Width',
                     'I Bin Num', 'Q Bin Num', 'I Bin Min', 'Q Bin Min',
                     'I Vector Perpendicular', 'Q Vector Perpendicular',
                     'I Line Point', 'Q Line Point']:
            self.setHistParams(name)

        for name in ['Integration time', 'Sample frequency']:
            self.setSamplingParams(name)

        for name in ['Number of records']:
            FPGA_PcPort_channel = 0
            record_num_val = self.getValue(name)
            record_num = np.zeros((2, 1), dtype=int)
            record_num[1] = np.int32(record_num_val)
            self.dig.FPGAwritePCport(FPGA_PcPort_channel, record_num, 0x1, keysightSD1.SD_AddressingMode.FIXED, keysightSD1.SD_AccessMode.NONDMA)

        self.smsb_info = np.zeros([self.num_of_demods, 4], dtype='int16')

    def getHwCh(self, n):
        """Get hardware channel number for channel n. n starts at 0"""
        return n + self.ch_index_zero

    def performClose(self, bError=False, options={}):
        """Perform the close instrument connection operation"""
        # do not check for error if close was called with an error
        try:
            # flush all memory
            for n in range(self.nCh):
                self.log('Close ch:', n, self.dig.DAQflush(self.getHwCh(n)))
            # close instrument
            self.dig.close()
        except:
            # never return error here
            pass

    def performSetValue(self, quant, value, sweepRate=0.0, options={}):
        """Perform the Set Value instrument operation. This function should
        return the actual value set by the instrument"""
        # start with setting local quant value
        quant.setValue(value)
        # check if channel-specific, if so get channel + name
        if quant.name.startswith('Ch') and len(quant.name) > 6:
            ch = int(quant.name[2]) - 1
            name = quant.name[6:]
        else:
            ch, name = None, ''
        if quant.name.startswith('FPGA Voltage') or quant.name.startswith('FPGA Single-shot'):
            demod_num = int(quant.name[-1]) - 1
        # proceed depending on command
        if quant.name in ('External Trig Source', 'External Trig Config',
                          'Trig Sync Mode'):
            extSource = int(self.getCmdStringFromValue('External Trig Source'))
            trigBehavior = int(self.getCmdStringFromValue('External Trig Config'))
            sync = int(self.getCmdStringFromValue('Trig Sync Mode'))
            self.dig.DAQtriggerExternalConfig(0, extSource, trigBehavior, sync)
        elif quant.name in ('Trig I/O', ):
            # get direction and sync from index of comboboxes
            direction = int(self.getCmdStringFromValue('Trig I/O'))
            self.dig.triggerIOconfig(direction)
        elif quant.name in ('Analog Trig Channel', 'Analog Trig Config', 'Trig Threshold'):
            # get trig channel
            trigCh = self.getValueIndex('Analog Trig Channel')
            mod = int(self.getCmdStringFromValue('Analog Trig Config'))
            threshold = self.getValue('Trig Threshold')
            self.dig.channelTriggerConfig(self.getHwCh(trigCh), mod, threshold)
        elif name in ('Range', 'Impedance', 'Coupling'):
            # set range, impedance, coupling at once
            rang = self.getRange(ch)
            imp = int(self.getCmdStringFromValue('Ch%d - Impedance' % (ch + 1)))
            coup = int(self.getCmdStringFromValue('Ch%d - Coupling' % (ch + 1)))
            self.dig.channelInputConfig(self.getHwCh(ch), rang, imp, coup)

        # FPGA configuration
        FPGA_PcPort_channel = 0
        if quant.name.startswith('LO freq'):
            demod_num = int(quant.name[-1])
            if demod_num == 1:
                LO_freq = self.getValue('LO freq ' + str(demod_num))
                self.setFPGALOfreq(LO_freq)

        elif quant.name in ['Skip time']:
            self.setFPGATrigger()

        elif quant.name in ['Analyze Mode', 'Stream', 'I Bin Width', 'Q Bin Width',
                            'I Bin Num', 'Q Bin Num', 'I Bin Min', 'Q Bin Min',
                            'I Vector Perpendicular', 'Q Vector Perpendicular',
                            'I Line Point', 'Q Line Point']:
            self.setHistParams(quant.name)

        elif quant.name in ['Integration time', 'Sample frequency']:
            self.setSamplingParams(quant.name)

        elif quant.name in ['Number of Records']:
            record_num_val = self.getValue(quant.name)
            record_num = np.zeros((2, 1), dtype=int)
            record_num[1] = np.int32(record_num_val)
            self.dig.FPGAwritePCport(FPGA_PcPort_channel, record_num, 0x1, keysightSD1.SD_AddressingMode.FIXED, keysightSD1.SD_AccessMode.NONDMA)

        return value

    def performGetValue(self, quant, options={}):
        """Perform the Set Value instrument operation. This function should
        return the actual value set by the instrument"""
        # check if channel-specific, if so get channel + name
        if quant.name.startswith('Ch') and len(quant.name) > 6:
            ch = int(quant.name[2]) - 1
            name = quant.name[6:]
        else:
            ch, name = None, ''

        if quant.name.startswith('FPGA Voltage') or quant.name.startswith('FPGA Single-shot'):
            demod_num = int(quant.name[-1]) - 1

        if name == 'Signal' or quant.name.startswith('FPGA'):
            self.log('FPGA output:')

            if self.isHardwareLoop(options):
                """Get data from round-robin type averaging"""
                (seq_no, n_seq) = self.getHardwareLoopIndex(options)
                nSample = int(self.getValue('Number of samples'))
                # if first sequence call, get data
                if seq_no == 0 and self.isFirstCall(options):
                    # show status before starting acquisition
                    self.reportStatus('Digitizer - Waiting for signal')
                    # get data
                    # self.getTracesHardware(n_seq)
                    self.getTraces(bArm=False, bMeasure=True, n_seq=n_seq)
                    # re-shape data and place in trace buffer
                    self.reshaped_traces = []
                    for trace in self.lTrace:
                        if len(trace) > 0:
                            trace = trace.reshape((n_seq, nSample))
                        self.reshaped_traces.append(trace)
                # after getting data, pick values to return
                if name == 'Signal':
                    return quant.getTraceDict(self.reshaped_traces[ch][seq_no], dt=self.dt)

            # get traces if first call
            if self.isFirstCall(options):
                # don't arm if in hardware trig mode
                self.getTraces(bArm=(not self.isHardwareTrig(options)))
            # return correct data
            if name == 'Signal':
                value = quant.getTraceDict(self.lTrace[ch], dt=self.dt)
            elif quant.name.startswith('FPGA I Value'):
                self.log('FPGA data_dump_i_val:', self.data_dump_i_val)
                value = self.data_dump_i_val[0]
            elif quant.name.startswith('FPGA Q Value'):
                self.log('FPGA data_dump_q_val:', self.data_dump_q_val)
                value = self.data_dump_q_val[0]
            elif quant.name.startswith('FPGA I-Q Complex Value'):
            #    self.log('FPGA data_dump_iq_complex_val:', self.data_dump_iq_complex_val)
                value = self.data_dump_iq_complex_val[0]
            elif quant.name.startswith('FPGA Excited Count'):
                value = self.classify_excited_count[0]
            elif quant.name.startswith('FPGA Ground Count'):
                value = self.classify_ground_count[0]
            elif quant.name.startswith('FPGA Line Count'):
                value = self.classify_line_count[0]
            elif quant.name.startswith('FPGA Classify State'):
                value = self.classify_state[0]
            elif quant.name.startswith('FPGA I Hist2D Bin'):
                value = self.histogram_i_bin[0]
                self.log('FPGA I Hist2D Bin:', self.histogram_i_bin[0])
            elif quant.name.startswith('FPGA Q Hist2D Bin'):
                value = self.histogram_q_bin[0]
                self.log('FPGA Q Hist2D Bin:', self.histogram_q_bin[0])
            elif quant.name.startswith('FPGA I-Q Hist2D Bin Complex'):
                value = self.histogram_iq_bin_complex[0]
                self.log('FPGA I-Q Hist2D Bin Complex:', self.histogram_iq_bin_complex[0])

        else:
            # for all others, return local value
            value = quant.getValue()

        return value

    def performArm(self, quant_names, options={}):
        """Perform the instrument arm operation"""
        # make sure we are arming for reading traces, if not return - commented by RoniW
        # signal_names = ['Ch%d - Signal' % (n + 1) for n in range(4)]
        # signal_arm = [name in signal_names for name in quant_names]
        # if not np.any(signal_arm):
        #    return

        # arm by calling get traces
        if self.isHardwareLoop(options):
            # in hardware looping, number of records is set by the hardware looping
            (seq_no, n_seq) = self.getHardwareLoopIndex(options)
            self.getTraces(bArm=True, bMeasure=False, n_seq=n_seq)
        else:
            self.getTraces(bArm=True, bMeasure=False)

    def getTraces(self, bArm=True, bMeasure=True, n_seq=0):
        """Get all active traces"""
        # # test timing
        # import time
        # t0 = time.clock()
        # lT = []

        # find out which traces to get
        lCh = []
        iChMask = 0
        self.log('Start Trace:')

        for n in range(self.nCh):
            if self.getValue('Ch%d - Enabled' % (n + 1)):
                lCh.append(n)
                iChMask += 2**n
        # get current settings
        # nDemods = int(self.getValue('Number of Demods'))
        nDemods = self.num_of_demods

        # nPts = max(int(self.getValue('Number of samples')), self.demod_sample_size)

        if self.fpga_config == 'Only signals (no FPGA - very slow)' or 'FPGA I/Q and signals (slow)':
            nPts = int(self.getValue('Number of samples'))
        elif self.fpga_config == self.fpga_config == 'Only FPGA I/Q (fast)':
            nPts = int(self.demod_sample_size)

        nCyclePerCall = int(self.getValue('Records per Buffer'))
        # in hardware loop mode, ignore records and use number of sequences
        if n_seq > 0:
            nSeg = n_seq
        else:
            nSeg = int(self.getValue('Number of records'))

        nAv = int(self.getValue('Number of averages'))
        # trigger delay is in 1/sample rate
        nTrigDelay = int(self.getValue('Trig Delay') / self.dt)

        if bArm:
            # clear old data
            self.dig.DAQflushMultiple(iChMask)
            self.lTrace = [np.array([])] * self.nCh
            self.lTrace_raw = [np.array([])] * self.nCh
            self.lTrace_raw[3] = np.zeros((nSeg * nPts))
            self.smsb_info_str = []
            self.data_dump_i_val = [0]
            self.data_dump_q_val = [0]
            self.data_dump_iq_complex_val = [0]
            self.classify_excited_count = [0]
            self.classify_ground_count = [0]
            self.classify_line_count = [0]
            self.classify_state = [0]
            self.histogram_i_bin = [0]
            self.histogram_q_bin = [0]
            self.histogram_iq_bin_complex = [0]

            # configure trigger for all active channels
            for nCh in lCh:
                # init data
                self.lTrace[nCh] = np.zeros((nSeg * nPts))
                # channel number depens on hardware version
                ch = self.getHwCh(nCh)
                # extra config for trig mode
                if self.getValue('Trig Mode') == 'Digital trigger':
                    extSource = int(self.getCmdStringFromValue('External Trig Source'))
                    trigBehavior = int(self.getCmdStringFromValue('External Trig Config'))
                    sync = int(self.getCmdStringFromValue('Trig Sync Mode'))
                    self.dig.DAQtriggerExternalConfig(ch, extSource, trigBehavior, sync)
                    self.dig.DAQdigitalTriggerConfig(ch, extSource, trigBehavior)
                elif self.getValue('Trig Mode') == 'Analog channel':
                    digitalTriggerMode= 0
                    digitalTriggerSource = 0
                    trigCh = self.getValueIndex('Analog Trig Channel')
                    analogTriggerMask = 2**trigCh
                    self.dig.DAQtriggerConfig(ch, digitalTriggerMode, digitalTriggerSource, analogTriggerMask)
                # config daq and trig mode
                trigMode = int(self.getCmdStringFromValue('Trig Mode'))
                self.dig.DAQconfig(ch, nPts, nSeg*nAv, nTrigDelay, trigMode)
            # start acquiring data
            self.dig.DAQstartMultiple(iChMask)
        # lT.append('Start %.1f ms' % (1000*(time.clock()-t0)))
        #
        # return if not measure
        if not bMeasure:
            return
        # define number of cycles to read at a time
        nCycleTotal = nSeg * nAv
        nCall = int(np.ceil(nCycleTotal / nCyclePerCall))
        lScale = [(self.getRange(ch) / self.bitRange) for ch in range(self.nCh)]
        # keep track of progress in percent
        old_percent = -1
        #self.log('nCall:' + str(nCall), level = 30)

        # proceed depending on segment or not segment
        if nSeg <= 1:
            # non-segmented acquisiton
            for n in range(nCall):
                # number of cycles for this call, could be fewer for last call
                nCycle = min(nCyclePerCall, nCycleTotal - (n * nCyclePerCall))
                #self.log('nCycle:' + str(nCycle), level = 30)

                # capture traces one by one
                for nCh in lCh:
                    # channel number depens on hardware version
                    ch = self.getHwCh(nCh)
                    data = self.DAQread(self.dig, ch, nPts * nCycle,
                                        int(1000 + self.timeout_ms / nCall))
                    # stop if no data
                    if data.size == 0:
                        return
                    if nCh==3:
                        #self.log('self.lTrace_raw[nCh]:' + str(self.lTrace_raw[nCh]), level = 30)
                        self.lTrace_raw[nCh] = data
                        self.getDemodValues(self.lTrace_raw[nCh], nPts, nSeg, nCycle)

                    # average
                    data = data.reshape((nCycle, nPts)).mean(0)
                    # adjust scaling to account for summing averages
                    scale = lScale[nCh] * (nCycle / nAv)
                    # convert to voltage, add to total average
                    self.lTrace[nCh] += data * scale

                # report progress, only report integer percent
                if nCall >= 1:
                    new_percent = int(100 * n / nCall)
                    if new_percent > old_percent:
                        old_percent = new_percent
                        self.reportStatus(
                            'Acquiring traces ({}%)'.format(new_percent) + ', FPGA Demod status (keep below 124): ' + ''.join(self.smsb_info_str))

                # break if stopped from outside
                if self.isStopped():
                    break
                # lT.append('N: %d, Tot %.1f ms' % (n, 1000 * (time.clock() - t0)))

        else:
            # segmented acquisition, get caLls per segment
            (nCallSeg, extra_call) = divmod(nSeg, nCyclePerCall)
            # pre-calculate list of cycles/call, last call may have more cycles
            if nCallSeg == 0:
                nCallSeg = 1
                lCyclesSeg = [nSeg]
            else:
                lCyclesSeg = [nCyclePerCall] * nCallSeg
                lCyclesSeg[-1] = nCyclePerCall + extra_call
            # pre-calculate scale, should include scaling for averaging
            lScale = np.array(lScale, dtype=float) / nAv

            for n in range(nAv):
                count = 0
                # loop over number of calls per segment
                #self.log('lCyclesSeg:' + str(lCyclesSeg), level = 30)
                for m, nCycle in enumerate(lCyclesSeg):

                    # capture traces one by one
                    for nCh in lCh:
                        # channel number depens on hardware version
                        ch = self.getHwCh(nCh)
                        data = self.DAQread(self.dig, ch, nPts * nCycle,
                                            int(1000 + self.timeout_ms / nCall))
                        # stop if no data
                        if data.size == 0:
                            return
                        # store all data in one long vector
                        self.lTrace[nCh][count:(count + data.size)] += \
                            data * lScale[nCh]
                        if nCh==3:
                            self.lTrace_raw[nCh][count:(count + data.size)] = data
                            #self.log(str(self.lTrace_raw[nCh]))
                    count += data.size
                self.getDemodValues(self.lTrace_raw[3], nPts, nSeg, nSeg)
                # report progress, only report integer percent
                if nAv >= 1:
                    new_percent = int(100 * n / nAv)
                    #self.log('new_percent:old_percent' + str(new_percent) + ':' + str(old_percent), level = 30)                    
                    if new_percent > old_percent:
                        old_percent = new_percent
                        self.reportStatus(
                            'Acquiring traces ({}%)'.format(new_percent) + ', FPGA Demod status (keep below 124): ' + ''.join(self.smsb_info_str))
                    
                # break if stopped from outside
                if self.isStopped():
                    break

                # lT.append('N: %d, Tot %.1f ms' % (n, 1000 * (time.clock() - t0)))

        # # log timing info
        # self.log(': '.join(lT))

    def getRange(self, ch):
        """Get channel range, as voltage.  Index start at 0"""
        rang = float(self.getCmdStringFromValue('Ch%d - Range' % (ch + 1)))
        return rang

    def DAQread(self, dig, nDAQ, nPoints, timeOut):
        """Read data directly to numpy array"""
        if dig._SD_Object__handle > 0:
            if nPoints > 0:
                data = (keysightSD1.c_short * nPoints)()
                nPointsOut = dig._SD_Object__core_dll.SD_AIN_DAQread(dig._SD_Object__handle, nDAQ, data, nPoints, timeOut)
                if nPointsOut > 0:
                    return np.frombuffer(data, dtype=np.int16, count=nPoints)
                else:
                    return np.array([], dtype=np.int16)
            else:
                return keysightSD1.SD_Error.INVALID_VALUE
        else:
            return keysightSD1.SD_Error.MODULE_NOT_OPENED

    def getDemodValues(self, data, nPts, nSeg, nCycle):
        """get Demod IQ data from Ch1/2/3 Trace"""
        accum_length = self.getValue('Integration time')
        nAv = self.getValue('Number of averages')
        lScale = [(self.getRange(ch) / self.bitRange) for ch in range(self.nCh)]
        demod_temp_I = np.zeros([self.num_of_demods, nCycle], dtype='complex')
        demod_temp_Q = np.zeros([self.num_of_demods, nCycle], dtype='complex')
        demod_temp_ref = np.zeros([self.num_of_demods, nCycle], dtype='complex')
        self.smsb_info_str = []
        # nDemods = int(self.getValue('Number of Demods'))
        nDemods = self.num_of_demods

        self.use_phase_ref = self.getValue('Use phase reference signal')

        analyze_mode = self.getValue("Analyze Mode")
        isStream = self.getValue("Stream")

        if analyze_mode == 'Data Dump':
            q_val_lsb = self.lTrace_raw[3][np.arange(20, nPts * nCycle, nPts)]
            q_val_msb = self.lTrace_raw[3][np.arange(21, nPts * nCycle, nPts)]
            i_val_lsb = self.lTrace_raw[3][np.arange(22, nPts * nCycle, nPts)]
            i_val_msb = self.lTrace_raw[3][np.arange(23, nPts * nCycle, nPts)]
            zeros = self.lTrace_raw[3][np.arange(24, nPts * nCycle, nPts)]
            q_val = q_val_lsb.astype('uint16') + (q_val_msb.astype('uint16') * (2**16))
            i_val = i_val_lsb.astype('uint16') + (i_val_msb.astype('uint16') * (2**16))

            self.data_dump_i_val = i_val.astype('int32') / 2**32 / accum_length * lScale[0]
            self.data_dump_q_val =  q_val.astype('int32') / 2**32 / accum_length * lScale[1]
            self.data_dump_iq_complex_val = self.data_dump_i_val + self.data_dump_q_val * 1j

        elif analyze_mode == 'Classify' and not isStream:
            line_val = self.lTrace_raw[3][np.arange(20, nPts * nCycle, nPts)]
            ground_val = self.lTrace_raw[3][np.arange(21, nPts * nCycle, nPts)]
            excited_val = self.lTrace_raw[3][np.arange(22, nPts * nCycle, nPts)]
            data_count = self.lTrace_raw[3][np.arange(23, nPts * nCycle, nPts)]
            zeros = self.lTrace_raw[3][np.arange(24, nPts * nCycle, nPts)]

            self.classify_excited_count = excited_val
            self.classify_ground_count = ground_val
            self.classify_line_count = line_val

        elif analyze_mode == 'Classify' and isStream:
            state_val = self.lTrace_raw[3][np.arange(20, nPts * nCycle, nPts)]
            zeros1 = self.lTrace_raw[3][np.arange(21, nPts * nCycle, nPts)]
            zeros2 = self.lTrace_raw[3][np.arange(22, nPts * nCycle, nPts)]
            zeros3 = self.lTrace_raw[3][np.arange(23, nPts * nCycle, nPts)]
            zeros4 = self.lTrace_raw[3][np.arange(24, nPts * nCycle, nPts)]
            
            self.classify_state = state_val

        elif analyze_mode == 'Histogram':
            hist_q = self.lTrace_raw[3][np.arange(20, nPts * nCycle, nPts)]
            hist_i = self.lTrace_raw[3][np.arange(21, nPts * nCycle, nPts)]
            zeros1 = self.lTrace_raw[3][np.arange(22, nPts * nCycle, nPts)]
            zeros2 = self.lTrace_raw[3][np.arange(23, nPts * nCycle, nPts)]
            zeros3 = self.lTrace_raw[3][np.arange(24, nPts * nCycle, nPts)]

            self.log("inHist!!!!!!!!!!!!!!!!!!!!!!!!!!!")
            self.histogram_i_bin = hist_i
            self.histogram_q_bin = hist_q
            self.histogram_iq_bin_complex = (hist_i*self.getValue('I Bin Width') + hist_q * 1j * self.getValue('Q Bin Width'))  + self.getValue('I Bin Min') + self.getValue('Q Bin Width') * 1j

    def setFPGALOfreq(self, demod_LO_freq):
        '''' Set Demod freq and LUT parameters'''
        FPGA_PcPort_channel = 0

        # Set Demoq freq
        demod_freq = np.zeros(2, dtype=int)  # Set up parameter list
        demod_freq_val = np.abs(demod_LO_freq) / 10e6  # Calculated demod_freq user input
        demod_freq[1] = np.int32(demod_freq_val)  # Set value in list

        # Set up LUT lists
        lut_0 = np.zeros(2, dtype=int)
        lut_1 = np.zeros(2, dtype=int)
        lut_2 = np.zeros(2, dtype=int)
        lut_3 = np.zeros(2, dtype=int)
        lut_4 = np.zeros(2, dtype=int)
        lut_5 = np.zeros(2, dtype=int)
        lut_6 = np.zeros(2, dtype=int)
        lut_7 = np.zeros(2, dtype=int)
        lut_8 = np.zeros(2, dtype=int)
        lut_9 = np.zeros(2, dtype=int)

        # Calculate LUT element values
        lut = [[0 for n in range(5)] for k in range(10)]
        for i in range(5):
            for j in range(10):
                lut[j][i] = ((5 * j + i) * demod_freq[1]) % 50

        # Concatenate LUT element values
        lut_0[1] = 0b00
        for i in range(4, -1, -1):
            lut_0[1] = lut_0[1] << 6 | lut[0][i]

        lut_1[1] = 0b00
        for i in range(4, -1, -1):
            lut_1[1] = lut_1[1] << 6 | lut[1][i]

        lut_2[1] = 0b00
        for i in range(4, -1, -1):
            lut_2[1] = lut_2[1] << 6 | lut[2][i]

        lut_3[1] = 0b00
        for i in range(4, -1, -1):
            lut_3[1] = lut_3[1] << 6 | lut[3][i]

        lut_4[1] = 0b00
        for i in range(4, -1, -1):
            lut_4[1] = lut_4[1] << 6 | lut[4][i]

        lut_5[1] = 0b00
        for i in range(4, -1, -1):
            lut_5[1] = lut_5[1] << 6 | lut[5][i]

        lut_6[1] = 0b00
        for i in range(4, -1, -1):
            lut_6[1] = lut_6[1] << 6 | lut[6][i]

        lut_7[1] = 0b00
        for i in range(4, -1, -1):
            lut_7[1] = lut_7[1] << 6 | lut[7][i]

        lut_8[1] = 0b00
        for i in range(4, -1, -1):
            lut_8[1] = lut_8[1] << 6 | lut[8][i]

        lut_9[1] = 0b00
        for i in range(4, -1, -1):
            lut_9[1] = lut_9[1] << 6 | lut[9][i]


        lo_demod_addr = 0xa

        buffer = np.zeros((2, 1), dtype=int)
        buffer[1] = 0  # valid bit to finalize the configuration
        self.dig.FPGAwritePCport(FPGA_PcPort_channel, buffer, 0x3, keysightSD1.SD_AddressingMode.FIXED, keysightSD1.SD_AccessMode.NONDMA)

        # Set LO frequency parameter in FPGA
        self.dig.FPGAwritePCport(FPGA_PcPort_channel, demod_freq, 0x0, keysightSD1.SD_AddressingMode.FIXED, keysightSD1.SD_AccessMode.NONDMA)

        # Set lookup table in FPGA
        self.dig.FPGAwritePCport(FPGA_PcPort_channel, np.int32(lut_0), lo_demod_addr, keysightSD1.SD_AddressingMode.FIXED, keysightSD1.SD_AccessMode.NONDMA)
        self.dig.FPGAwritePCport(FPGA_PcPort_channel, np.int32(lut_1), lo_demod_addr + 1, keysightSD1.SD_AddressingMode.FIXED, keysightSD1.SD_AccessMode.NONDMA)
        self.dig.FPGAwritePCport(FPGA_PcPort_channel, np.int32(lut_2), lo_demod_addr + 2, keysightSD1.SD_AddressingMode.FIXED, keysightSD1.SD_AccessMode.NONDMA)
        self.dig.FPGAwritePCport(FPGA_PcPort_channel, np.int32(lut_3), lo_demod_addr + 3, keysightSD1.SD_AddressingMode.FIXED, keysightSD1.SD_AccessMode.NONDMA)
        self.dig.FPGAwritePCport(FPGA_PcPort_channel, np.int32(lut_4), lo_demod_addr + 4, keysightSD1.SD_AddressingMode.FIXED, keysightSD1.SD_AccessMode.NONDMA)
        self.dig.FPGAwritePCport(FPGA_PcPort_channel, np.int32(lut_5), lo_demod_addr + 5, keysightSD1.SD_AddressingMode.FIXED, keysightSD1.SD_AccessMode.NONDMA)
        self.dig.FPGAwritePCport(FPGA_PcPort_channel, np.int32(lut_6), lo_demod_addr + 6, keysightSD1.SD_AddressingMode.FIXED, keysightSD1.SD_AccessMode.NONDMA)
        self.dig.FPGAwritePCport(FPGA_PcPort_channel, np.int32(lut_7), lo_demod_addr + 7, keysightSD1.SD_AddressingMode.FIXED, keysightSD1.SD_AccessMode.NONDMA)
        self.dig.FPGAwritePCport(FPGA_PcPort_channel, np.int32(lut_8), lo_demod_addr + 8, keysightSD1.SD_AddressingMode.FIXED, keysightSD1.SD_AccessMode.NONDMA)
        self.dig.FPGAwritePCport(FPGA_PcPort_channel, np.int32(lut_9), lo_demod_addr + 9, keysightSD1.SD_AddressingMode.FIXED, keysightSD1.SD_AccessMode.NONDMA)

        buffer[1] = 1  # valid bit to finalize the configuration
        self.dig.FPGAwritePCport(FPGA_PcPort_channel, buffer, 0x3, keysightSD1.SD_AddressingMode.FIXED, keysightSD1.SD_AccessMode.NONDMA)

        value = np.int32(demod_LO_freq / 10e6)

        return value

    def setFPGATrigger(self):
        ''' Set Skip time parameter'''
        FPGA_PcPort_channel = 0
        skip_time = np.int32(np.floor(self.getValue('Skip time') / 10e-9))
        buffer = np.zeros((2, 1), dtype=int)
        buffer[1] = np.int32(skip_time)
        self.dig.FPGAwritePCport(FPGA_PcPort_channel, buffer, 0x16, keysightSD1.SD_AddressingMode.FIXED, keysightSD1.SD_AccessMode.NONDMA)
        buffer[1] = 1  # valid bit to finalize the configuration
        self.dig.FPGAwritePCport(FPGA_PcPort_channel, buffer, 0x3, keysightSD1.SD_AddressingMode.FIXED, keysightSD1.SD_AccessMode.NONDMA)

    def setHistParams(self, param):
        ''' Set Histogram 2D parameters'''
        FPGA_PcPort_channel = 0

        if param in ['Analyze Mode']:
            analyze_mode = np.zeros((2, 1), dtype=int)
            if self.getValueIndex(param) == 2:
                analyze_mode[1] = np.int32(3)
            else:
                analyze_mode[1] = np.int32(self.getValueIndex(param))

            self.log('Analyze Mode:', analyze_mode)
            self.dig.FPGAwritePCport(FPGA_PcPort_channel, analyze_mode, 0x1e, keysightSD1.SD_AddressingMode.FIXED, keysightSD1.SD_AccessMode.NONDMA)
            value = analyze_mode[1]
        elif param in ['Stream']:
            isStream = np.zeros((2, 1), dtype=int)
            isStream[1] = np.int32(self.getValue(param))
            self.log('Stream:', isStream)
            self.dig.FPGAwritePCport(FPGA_PcPort_channel, isStream, 0x02, keysightSD1.SD_AddressingMode.FIXED, keysightSD1.SD_AccessMode.NONDMA)
            value = isStream[1]
        elif param in ['I Bin Width', 'Q Bin Width']:
            bin_width = np.zeros((2, 1), dtype=int)
            bin_width[1] = np.int32(self.getValue(param))
            if param == 'I Bin Width':
                address = 0x1f
                self.log('I Bin Width:', bin_width)
            else:
                address = 0x20
                self.log('Q Bin Width:', bin_width)
            self.dig.FPGAwritePCport(FPGA_PcPort_channel, bin_width, address, keysightSD1.SD_AddressingMode.FIXED, keysightSD1.SD_AccessMode.NONDMA)
            value = bin_width[1]
        elif param in ['I Bin Num', 'Q Bin Num']:
            bin_num = np.zeros((2, 1), dtype=int)
            bin_num[1] = np.int32(self.getValue(param))
            if param == 'I Bin Num':
                address = 0x21
                self.log('I Bin Num:', bin_num)
            else:
                address = 0x22
                self.log('Q Bin Num:', bin_num)
            self.dig.FPGAwritePCport(FPGA_PcPort_channel, bin_num, address, keysightSD1.SD_AddressingMode.FIXED, keysightSD1.SD_AccessMode.NONDMA)
            value = bin_num[1]
        elif param in ('I Bin Min', 'Q Bin Min'):
            bin_min = np.zeros((2, 1), dtype=int)
            bin_min[1] = np.int32(self.getValue(param))
            if param == 'I Bin Min':
                address = 0x23
                self.log('I Bin Min:', bin_min)
            else:
                address = 0x24
                self.log('Q Bin Min:', bin_min)
            self.dig.FPGAwritePCport(FPGA_PcPort_channel, bin_min, address, keysightSD1.SD_AddressingMode.FIXED, keysightSD1.SD_AccessMode.NONDMA)
            value = bin_min[1]
        elif param in ('I Vector Perpendicular', 'Q Vector Perpendicular'):
            vec_perp = np.zeros((2, 1), dtype=int)
            vec_perp[1] = np.int32(self.getValue(param))
            if param == 'I Vector Perpendicular':
                address = 0x25
                self.log('I Vector Perpendicular:', vec_perp)
            else:
                address = 0x26
                self.log('Q Vector Perpendicular:', vec_perp)
            self.dig.FPGAwritePCport(FPGA_PcPort_channel, vec_perp, address, keysightSD1.SD_AddressingMode.FIXED, keysightSD1.SD_AccessMode.NONDMA)
            value = vec_perp[1]
        elif param in ('I Line Point', 'Q Line Point'):
            line_pt = np.zeros((2, 1), dtype=int)
            line_pt[1] = np.int32(self.getValue(param))
            if param == 'I Line Point':
                address = 0x27
                self.log('I Line Point:', line_pt)
            else:
                address = 0x28
                self.log('Q Line Point:', line_pt)
            self.dig.FPGAwritePCport(FPGA_PcPort_channel, line_pt, address, keysightSD1.SD_AddressingMode.FIXED, keysightSD1.SD_AccessMode.NONDMA)
            value = line_pt[1]

        buffer = np.zeros((2, 1), dtype=int)
        buffer[1] = 1  # valid bit to finalize the configuration
        self.dig.FPGAwritePCport(FPGA_PcPort_channel, buffer, 0x3, keysightSD1.SD_AddressingMode.FIXED, keysightSD1.SD_AccessMode.NONDMA)

        return value

    def setSamplingParams(self, param):
        ''' Set Sampling parameters'''
        FPGA_PcPort_channel = 0

        sample_skip = np.zeros((2, 1), dtype=int)
        sample_length = np.zeros((2, 1), dtype=int)

        sample_freq = self.getValue('Sample frequency')
        sample_skip_val = int(500e6 / sample_freq)
        sample_skip[1] = np.int32(sample_skip_val)

        int_time = self.getValue('Integration time')
        sample_length_val = math.ceil(int_time * 100e6)

        sample_length[1] = np.int32(sample_length_val)

        self.dig.FPGAwritePCport(FPGA_PcPort_channel, sample_length, 0x14, keysightSD1.SD_AddressingMode.FIXED, keysightSD1.SD_AccessMode.NONDMA)
        self.dig.FPGAwritePCport(FPGA_PcPort_channel, sample_skip, 0x15, keysightSD1.SD_AddressingMode.FIXED, keysightSD1.SD_AccessMode.NONDMA)
        buffer = np.zeros((2, 1), dtype=int)
        buffer[1] = 1  # valid bit to finalize the configuration
        self.dig.FPGAwritePCport(FPGA_PcPort_channel, buffer, 0x3, keysightSD1.SD_AddressingMode.FIXED, keysightSD1.SD_AccessMode.NONDMA)

        if param == 'Sample frequency':
            value = sample_skip_val
        else:
            value = sample_length_val

        return value


if __name__ == '__main__':
    pass
