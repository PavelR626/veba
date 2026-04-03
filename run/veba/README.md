### Running Jobs via GNU Parallel on EC2 or Locally

1. Generate sample-specific commands list:
    ```
    bash generate_preprocess_commands.sh
    ```
2. Start a `screen` session: 
    ```
    screen -S veba
    ```

3. Activate `VEBA` controller environment from within `screen` session:
    ```
    mamba activate VEBA
    ```

4. Run commands list using GNU Parallel:
    ```
    n_concurrent_jobs=4
    cat commands.preprocess.list | parallel -j ${n_concurrent_jobs}
    ```
    Note: The first time using GNU parallel with ask you to cite interactively

5. Detach from `screen` session:
    ```
    [ctrl]+[a]
    ```
6a. Monitor progress with either `top` or `btop`

6b. Monitor logs for a particular file: 
    ```
    # stdout
    tail -f -n +1 logs/preprocess__S1.o
    # stderr
    tail -f -n +1 logs/preprocess__S1.e
    ```
7. Reattach `screen` session:
    ```
    screen -r veba
    ```
8. Run next list of commands
9. Alternatively, run all at once (not recommended and not thoroughly tested)
    ```
    bash run_workflow.sh
    ```
    Note: You need to make sure that `$VEBA_DATABASE` is properly set in all files
10. Quit `screen` session:
    ```
    exit
    ```