import cmath
import math
import numpy as np

def gen_shuffle_idx(cur_idx):
    """
    generate the shuffle index.
    """
    if cur_idx.shape[0] == 1: 
        return cur_idx
    even_half = cur_idx[0::2]
    odd_half = cur_idx[1::2]
    return np.concatenate((gen_shuffle_idx(even_half),gen_shuffle_idx(odd_half)))



def sim_stage(n, ip, shuffle_idx):
    """
    Simulated operation of a single butterfly stage.
    Arguments:
        n:              stage number (starting from 1)
        ip:             input from the previous stage
        shuffle_idx:    how the index is split and rearranged
    Return:
        output of the current stage (length equal to ip)
    """
    op = []
    N = math.log(len(ip),2)
    if int(N) != N:
        print("input length must be 2^N!")
        exit()
    N = int(N)
    if n > N:
        return None
    delay = 2**(N-n)
    buf = np.zeros(delay).astype(np.complex64)
    timemux_clk = 0
    twiddle_val = 1
    twiddle_idx = -1
    timemux_period = 2*delay
    twiddle_period = timemux_period
    twiddle_base = 2**(n)
    ip = np.concatenate((ip, np.zeros(delay)))
    for i in range(delay+2**N):
        # setup twiddle value
        if not i%delay: timemux_clk = not timemux_clk
        if not i%twiddle_period:    twiddle_idx += 1
        if timemux_clk:
            twiddle_val = 1
        else:
            twiddle_exp = shuffle_idx[twiddle_idx]/2**(N-n+1)
            twiddle_val = cmath.exp(-2*cmath.pi*1j*twiddle_exp/twiddle_base)
        # shift buf / butterfly
        if timemux_clk:
            # shift buf
            op += [buf[0]]
            buf[0:-1] = buf[1:]
            assert twiddle_val == 1
            buf[-1] = ip[i]*twiddle_val
        else:
            # butterfly
            _plus = buf[0] + ip[i]*twiddle_val
            _minus = buf[0] - ip[i]*twiddle_val
            buf[0:-1] = buf[1:]
            buf[-1] = _minus
            op += [_plus]
    return np.array(op[delay:])



def sim_flow(ip, verbose=False):
    """
    Simulated operation of all butterfly stages concatenated.
    Arguments:
        ip: a list in time domain
    Return:
        freq domain components
    """
    shuffle_idx = gen_shuffle_idx(np.arange(ip.shape[0]))
    n = 1
    while ip is not None:
        op = ip
        if verbose:
            print('-- real, imag '+'-'*80)
            _ = np.array([i.real for i in op])
            l = _.shape[0]
            fmt = '  '.join(['{:.2f}']*l)
            print(fmt.format(*_))
            _ = np.array([i.imag for i in op])
            print(fmt.format(*_))
        ip = sim_stage(n, ip, shuffle_idx)
        n += 1
    return op[shuffle_idx]
