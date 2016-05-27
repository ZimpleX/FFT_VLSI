import numpy as np
import argparse

f_name = 'ip_arr.v'
def parse_args():
    parser = argparse.ArgumentParser('generate tb data')
    parser.add_argument('--dtype', type=str, choices=['real','int'], required=True, help='data format')
    parser.add_argument('--N', type=int, default=4, help='generate 2^N inputs')
    return parser.parse_args()


def main(dtype, N):
    n = (2**N)*3
    f_name = 'ip_arr_{}.v'.format(dtype)
    f = open(f_name, 'w')
    conv = (dtype=='int') and int or float
    for i in range(n):
        f.write('ip_arr_raw[{}] = {};\n'\
            .format(i, conv(np.random.rand(1)[0]*15)))


if __name__ == '__main__':
    args = parse_args()
    main(args.dtype, args.N)
