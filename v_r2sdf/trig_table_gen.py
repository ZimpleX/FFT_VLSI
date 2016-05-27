import math
import argparse


def parse_args():
    parser = argparse.ArgumentParser('generate trig tabe')
    parser.add_argument('--dtype', type=str, choices=['real','fpt'], required=True, help='data format')
    parser.add_argument('--N', type=int, default=8, help='partition pi into 2^N parts')
    return parser.parse_args()
    
def decimal_to_binary(v, prefix, num_digit=16):
    assert v >= 0
    s = 0.
    for exp in range(num_digit):
        if not exp%4: prefix += '_'
        if s <= v and s+2**(-exp-1) > v:
            prefix += '0'
        else:
            s += 2**(-exp-1)
            prefix += '1'
    return prefix


def trig_fixed_point(v):
    if v>=0:
        prefix = '32\'b0000_0000_0000_0000'
        ret = decimal_to_binary(v, prefix)
    else:
        prefix = '32\'b1111_1111_1111_1111'
        ret = decimal_to_binary(1+v, prefix)
    return ret

def main(dtype, N):
    n = 2**N
    f_name = 'trigonometric_table_{}.v'.format(dtype)
    f = open(f_name, 'w')
    f.write('parameter MAX_N = {};\n'.format(N))
    trig_dict = {'cos': (math.cos,1), 
                'sin': (math.sin,-1)}
    for trig in trig_dict:
        f.write('parameter fpt {} [0:(1<<MAX_N)-1] = {{\n'.format(trig))
        for i in range(n):
            deli = (i==n-1) and ' ' or ','
            func = trig_dict[trig][0]
            sign = trig_dict[trig][1]
            if dtype == 'fpt':
                f.write('    {}{}\n'.format( \
                    trig_fixed_point(sign*func(i/n*math.pi)),deli))
            else:
                f.write('    {:.3f}{}\n'.format( \
                    sign*func(i/n*math.pi),deli))
        f.write('};\n')




if __name__ == '__main__':
    args = parse_args()
    main(args.dtype, args.N)
