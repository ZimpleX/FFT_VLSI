import algo
import numpy as np
import argparse

def parse_args():
    parser = argparse.ArgumentParser("test R2SDF FFT")
    parser.add_argument('-N', '--N_ip', type=int, required=True, help='use 2^N inputs')
    parser.add_argument('-s', '--seed', type=int, default=-1, help='random seed for input vector')
    return parser.parse_args()


ip = np.array([
11,
10,
2,
3,
1,
3,
21,
31,
0,
10,
2,
3,
1,
3,
21,
31
])

if __name__ == '__main__':
    args = parse_args()
    if args.seed >= 0:
        np.random.seed(args.seed)
    #ip = np.random.randn(args.N_ip).astype(np.complex64)
    f_name = '../v_r2sdf/ip_arr.v'
    f = open(f_name)
    line = f.read().split('\n')[0:-1]
    #import pdb; pdb.set_trace()
    num = np.array([float(i.split(' ')[-1][0:-1]) for i in line])
    for r in range(5):
        ip = num[r*(2**args.N_ip):(r+1)*(2**args.N_ip)]
        if ip.shape[0] < 2**args.N_ip:
            exit()
        print('\n\n'+'='*100)
        print(ip)
        op_np_fft = np.around(np.fft.fft(ip), decimals=3)
        op_r2sdf_fft = np.around(algo.sim_flow(ip), decimals=3)
        if np.array_equal(op_r2sdf_fft, op_np_fft):
            print("test PASSED!")
        else:
            print("fft output:\n{}".format(op_np_fft))
            print("algo output:\n{}".format(op_r2sdf_fft))
            print("test FAILED!")
        print('-'*100)
        print('-- correct      '+'-'*80)
        l = op_np_fft.shape[0]
        fmt = '  '.join(['{:.2f}']*l)
        _ = np.array([i.real for i in op_np_fft])
        print(fmt.format(*_))
        _ = np.array([i.imag for i in op_np_fft])
        print(fmt.format(*_))
