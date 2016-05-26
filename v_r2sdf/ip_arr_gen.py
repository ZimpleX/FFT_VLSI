import numpy as np

f_name = 'ip_arr.v'

if __name__ == '__main__':
    N = 4
    n = (2**4)*3
    f = open(f_name, 'w')
    for i in range(n):
        f.write('ip_arr[{}] = {:.3f};\n'.format(i,np.random.rand(1)[0]*100-50))
