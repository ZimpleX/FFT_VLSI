### Utility scripts for helping debug Verilog design

#### Requirement:
* `python3`
    - `numpy`, `argparse` package
* Simple installation: [Anaconda](https://www.continuum.io/downloads)

#### Usage:
* Command line: `python3 test.py -h` to see options
    - e.g., `python3 test.py -f ../v_r2sdf/ip_arr_int.v -N 4 -v`
* Interactive shell: 
    - `import test`
    - `test.main(5, '../v_r2sdf/ip_arr_int.v', 4, verbose=True)`
