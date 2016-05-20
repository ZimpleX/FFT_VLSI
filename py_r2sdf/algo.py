import cmath
import math
import numpy as np

def sim_stage(n, ip):
    """
    Simulated operation of a single butterfly stage.
    Arguments:
        n:  stage number (starting from 1)
        ip: input from the previous stage
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
    twiddle_exp = -1
    timemux_period = 2*delay
    twiddle_period = timemux_period
    twiddle_base = 2**(n)
    ip = np.concatenate((ip, np.zeros(delay)))
    for i in range(delay+2**N):
        # setup twiddle value
        if not i%delay: timemux_clk = not timemux_clk
        if not i%twiddle_period:    twiddle_exp += 1
        print("{},{}".format(twiddle_exp,twiddle_base))
        if timemux_clk:
            twiddle_val = 1
        else:
            twiddle_val = cmath.exp(-2*cmath.pi*1j*twiddle_exp/twiddle_base)
            print("\t\t{}, {}".format(twiddle_val, -2j*twiddle_exp/twiddle_base))
        # shift buf / butterfly
        if timemux_clk:
            # shift buf
            op += [buf[0]]
            buf[0:-1] = buf[1:]
            assert twiddle_val == 1
            buf[-1] = ip[i]*twiddle_val
        else:
            # butterfly
            print("{} + {}*{}".format(buf[0],ip[i],twiddle_val))
            _plus = buf[0] + ip[i]*twiddle_val
            _minus = buf[0] - ip[i]*twiddle_val
            buf[0:-1] = buf[1:]
            buf[-1] = _minus
            op += [_plus]
    return np.array(op[delay:])



def sim_flow(ip):
    """
    Simulated operation of all butterfly stages concatenated.
    Arguments:
        ip: a list in time domain
    Return:
        freq domain components
    """
    n = 1
    while ip is not None:
        op = ip
        print("--------")
        print(n)
        print('--------')
        print(op.reshape(-1,1))
        ip = sim_stage(n, ip)
        n += 1
    return op
