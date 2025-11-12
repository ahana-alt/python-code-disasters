from multiprocessing import Process

def split_list(alist, wanted_parts=1)
    """Split a list into equal parts."""
    length = len(alist)
    return [
        alist[i * length // wanted_parts: (i + 1) * length // wanted_parts] 
        for i in range(wanted_parts)
    ]

def check_ip(iplist, masklist):
    """Check IP addresses using multiprocessing."""
    threads = 16
    # Refactored: cleaner list splitting
    work_list = split_list(iplist, threads)
    
    processes = [
        Process(target=include_worker, args=(work_list[i], masklist)) 
        for i in range(threads)
    ]
    
    for process in processes:
        process.start()
    
    for process in processes:
        process.join()
