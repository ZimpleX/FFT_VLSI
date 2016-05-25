import math

f_name = 'trigonometric_table.v'

if __name__ == '__main__':
    N = 9
    n = 2**9
    f = open(f_name, 'w')
    f.write('parameter MAX_N = {};\n'.format(N))
    f.write('parameter real cos [0:(1<<MAX_N)-1] = {\n')
    for i in range(n):
        deli = ','
        if i == n-1:
            deli = ''
        f.write('    {:.3f}{}\n'.format(math.cos(i/n*math.pi),deli))
    f.write('};\n')
    f.write('parameter real sin [0:(1<<MAX_N)-1] = {\n')
    for i in range(n):
        deli = ','
        if i == n-1:
            deli = ''
        f.write('    {:.3f}{}\n'.format(math.sin(i/n*math.pi),deli))
    f.write('};\n')
