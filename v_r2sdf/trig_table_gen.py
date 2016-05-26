import math

f_name = 'trigonometric_table.v'

def fixed_point(v):
    if v>=0:
        ret = '32\'b0000_0000_0000_0000'
        s = 0.
        for exp in range(16):
            if not exp%4: ret += '_'
            if s <= v and s + 2**(-exp-1) > v:
                ret += '0'
            else:
                s += 2**(-exp-1)
                ret += '1'
    else:
        ret = '32\'b1111_1111_1111_1111'
        v = 1+v
        s = 0.
        for exp in range(16):
            if not exp%4: ret += '_'
            if s <= v and s + 2**(-exp-1) > v:
                ret += '0'
            else:
                s += 2**(-exp-1)
                ret += '1'
    return ret

if __name__ == '__main__':
    N = 9
    n = 2**9
    f = open(f_name, 'w')
    f.write('parameter MAX_N = {};\n'.format(N))
    f.write('parameter fpt cos [0:(1<<MAX_N)-1] = {\n')
    for i in range(n):
        deli = ','
        if i == n-1:
            deli = ''
        #f.write('    {}{}\n'.format(fixed_point(math.cos(i/n*math.pi)),deli))
        f.write('    {:.3f}{}\n'.format(math.cos(i/n*math.pi),deli))
    f.write('};\n')
    f.write('parameter fpt sin [0:(1<<MAX_N)-1] = {\n')
    for i in range(n):
        deli = ','
        if i == n-1:
            deli = ''
        #f.write('    {}{}\n'.format(fixed_point(-math.sin(i/n*math.pi)),deli))
        f.write('    {:.3f}{}\n'.format(-math.sin(i/n*math.pi),deli))
    f.write('};\n')
