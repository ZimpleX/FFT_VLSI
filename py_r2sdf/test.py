import algo
import numpy as np
import argparse

def parse_args():
    parser = argparse.ArgumentParser("test R2SDF FFT")
    parser.add_argument('-N', '--N_ip', type=int, required=True, help='use 2^N inputs')
    parser.add_argument('-s', '--seed', type=int, default=-1, help='random seed for input vector')
    parser.add_argument('-f', '--ip_data_file', type=str, default=None, help='provide input from the specified input file')
    parser.add_argument('-v', '--verbose', action='store_true', default=False, help='print out intermediate stage output')
    return parser.parse_args()


def main(itr):
    args = parse_args()
    if args.ip_data_file is None:
        if args.seed >= 0:
            np.random.seed(args.seed)
        num = np.random.randn(itr*args.N_ip).astype(np.complex64)
    else:
        f_name = args.ip_data_file
        f = open(f_name)
        line = f.read().split('\n')[0:-1]
        num = np.array([float(i.split(' ')[-1][0:-1]) for i in line])
    for r in range(itr):
        ip = num[r*(2**args.N_ip):(r+1)*(2**args.N_ip)]
        if ip.shape[0] < 2**args.N_ip:
            exit()
        op_np_fft = np.around(np.fft.fft(ip), decimals=3)
        op_r2sdf_fft = np.around(algo.sim_flow(ip,args.verbose), decimals=3)
        if np.array_equal(op_r2sdf_fft, op_np_fft):
            print("\n\n============")
            print("test PASSED!")
            print("============\n\n")
        else:
            print("\n\n************")
            print("test FAILED!")
            print("************\n\n")
        if args.verbose:
            print('-'*100)
            print('----   correct      '+'-'*80)
            l = op_np_fft.shape[0]
            fmt = '  '.join(['{:.2f}']*l)
            _ = np.array([i.real for i in op_np_fft])
            print(fmt.format(*_))
            _ = np.array([i.imag for i in op_np_fft])
            print(fmt.format(*_))


if __name__ == '__main__':
    main(5)
