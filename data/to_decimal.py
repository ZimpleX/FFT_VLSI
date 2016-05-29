import argparse

def parse_args():
    parser = argparse.ArgumentParser("convert FFT fx16.32 data to decimal")
    parser.add_argument('-f', '--file', type=str, required=True, help='the input file to convert')
    return parser.parse_args()

def convert(hex_str, decimal_pos=16):
    hex_str = hex_str.strip()
    ret = int(hex_str,16)*(2**(-decimal_pos))
    if int(hex_str[0],16) >= 8:
        ret -= 2**(32-decimal_pos)
    return ret


def main(f_name):
    f_name_out = ['decimal'] + f_name.split('.')[0:-1] + ['log']
    f_name_out = '.'.join(f_name_out)
    with open(f_name, 'r') as f_in:
        with open(f_name_out, 'w') as f_out:
            line = f_in.read().split('\n')
            line = [x for x in line if (x and 'xxxx' not in x)]
            for l in line:
                real,imag  = l.split(',')
                real,imag =[convert(real),convert(imag)]
                f_out.write('{:.3f}, {:.3f}\n'.format(real,imag))



if __name__ == '__main__':
    args = parse_args()
    main(args.file)
