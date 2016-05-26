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
    op_np_fft = np.around(np.fft.fft(ip), decimals=3)
    op_r2sdf_fft = np.around(algo.sim_flow(ip), decimals=3)
    if np.array_equal(op_r2sdf_fft, op_np_fft):
        print("test PASSED!")
    else:
        print("fft output:\n{}".format(op_np_fft))
        print("algo output:\n{}".format(op_r2sdf_fft))
        print("test FAILED!")
