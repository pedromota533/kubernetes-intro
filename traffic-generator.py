#!/usr/bin/env python3
"""
Traffic generator for nginx load balancer testing.
Uses multiprocessing (fork) to generate maximum load.
"""

import requests
import multiprocessing
import threading
import time
from datetime import datetime

# Configuration
NGINX_URL = "http://localhost:30080"
NUM_PROCESSES = 5
THREADS_PER_PROCESS = 5
REQUESTS_PER_THREAD = 100000
DELAY_BETWEEN_REQUESTS = 0  # seconds


def worker_thread(process_id, thread_id, stats):
    """Thread worker - makes HTTP requests."""
    successful = 0
    failed = 0

    for i in range(REQUESTS_PER_THREAD):
        try:
            response = requests.get(NGINX_URL, timeout=5)

            if response.status_code == 200:
                successful += 1
            else:
                failed += 1

        except requests.exceptions.RequestException:
            failed += 1

        if DELAY_BETWEEN_REQUESTS > 0:
            time.sleep(DELAY_BETWEEN_REQUESTS)

    stats['successful'] += successful
    stats['failed'] += failed


def make_requests(process_id, results_queue):
    """Process worker - spawns threads to make requests."""
    # Shared stats for this process
    manager = multiprocessing.Manager()
    stats = manager.dict()
    stats['successful'] = 0
    stats['failed'] = 0

    # Create and start threads within this process
    threads = []
    for i in range(THREADS_PER_PROCESS):
        thread = threading.Thread(target=worker_thread, args=(process_id, i+1, stats))
        threads.append(thread)
        thread.start()

    # Wait for all threads to complete
    for thread in threads:
        thread.join()

    print(f"[Process {process_id:2d}] Completed - Success: {stats['successful']}, Failed: {stats['failed']}")
    results_queue.put({'successful': stats['successful'], 'failed': stats['failed']})


def main():
    """Run traffic generator using multiprocessing + threading."""
    total_requests = NUM_PROCESSES * THREADS_PER_PROCESS * REQUESTS_PER_THREAD

    print("=" * 60)
    print("Nginx Traffic Generator (Multiprocessing + Threading)")
    print("=" * 60)
    print(f"Target URL: {NGINX_URL}")
    print(f"Processes: {NUM_PROCESSES}")
    print(f"Threads per process: {THREADS_PER_PROCESS}")
    print(f"Requests per thread: {REQUESTS_PER_THREAD}")
    print(f"Total concurrent workers: {NUM_PROCESSES * THREADS_PER_PROCESS}")
    print(f"Total requests: {total_requests:,}")
    print(f"Delay between requests: {DELAY_BETWEEN_REQUESTS}s")
    print("=" * 60)
    print()

    start_time = time.time()

    # Create queue for collecting results
    results_queue = multiprocessing.Queue()

    # Create and start processes
    processes = []
    for i in range(NUM_PROCESSES):
        process = multiprocessing.Process(target=make_requests, args=(i+1, results_queue))
        processes.append(process)
        process.start()

    # Wait for all processes to complete
    for process in processes:
        process.join()

    end_time = time.time()
    duration = end_time - start_time

    # Collect results from all processes
    total_successful = 0
    total_failed = 0
    while not results_queue.empty():
        result = results_queue.get()
        total_successful += result['successful']
        total_failed += result['failed']

    # Print summary
    print()
    print("=" * 60)
    print("Summary")
    print("=" * 60)
    print(f"Total requests: {total_successful + total_failed}")
    print(f"Successful: {total_successful}")
    print(f"Failed: {total_failed}")
    print(f"Duration: {duration:.2f}s")
    print(f"Requests/second: {(total_successful + total_failed) / duration:.2f}")
    print("=" * 60)


if __name__ == "__main__":
    main()
