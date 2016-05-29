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


def main(ip_data_file, N_ip, seed=None, verbose=False, itr=5):
    if ip_data_file is None:
        if seed >= 0:
            np.random.seed(seed)
        num = np.random.randn(itr*N_ip).astype(np.complex64)
    else:
        f_name = ip_data_file
        f = open(f_name)
        line = f.read().split('\n')[0:-1]
        num = np.array([float(i.split(' ')[-1][0:-1]) for i in line])
    for r in range(itr):
        i_s = r*(2**N_ip)
        i_e = i_s + (2**N_ip)
        ip = num[i_s:i_e]
        if ip.shape[0] < 2**N_ip:
            exit()
        print('-'*127)
        print('----  INPUT ({:3d} to {:3d}): '.format(i_s,i_e)+'-'*101)
        l = ip.shape[0]
        fmt = ' '.join(['{:7.2f}']*l)
        print(fmt.format(*ip))
        print('-'*127)
        op_np_fft = np.around(np.fft.fft(ip), decimals=3)
        op_r2sdf_fft = np.around(algo.sim_flow(ip,verbose), decimals=3)
        if np.array_equal(op_r2sdf_fft, op_np_fft):
            print("============")
            print("test PASSED!")
            print("============")
        else:
            print("************")
            print("test FAILED!")
            print("************")
        print('-'*127)
        print('----  CORRECT FINAL OUTPUT ({:3d} to {:3d}): real(row0), imag(row1) '.format(i_s,i_e)+'-'*63)
        l = op_np_fft.shape[0]
        fmt = ' '.join(['{:7.2f}']*l)
        _ = np.array([i.real for i in op_np_fft])
        print(fmt.format(*_))
        _ = np.array([i.imag for i in op_np_fft])
        print(fmt.format(*_))
        print('-'*127)
        print('\n'*2)


if __name__ == '__main__':
    args = parse_args()
    main(args.ip_data_file, args.N_ip, seed=args.seed, verbose=args.verbose, itr=5)
