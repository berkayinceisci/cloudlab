#!/bin/bash

get_sysinfo() {
    uname -a
    echo "--------------------------"
    sudo numactl --hardware
    echo "--------------------------"
    lscpu
    echo "--------------------------"
    cat /proc/cpuinfo
    echo "--------------------------"
    cat /proc/meminfo
}

disable_thp() {
    echo "never" | sudo tee /sys/kernel/mm/transparent_hugepage/enabled >/dev/null 2>&1
}

disable_numa_balancing() {
    echo 0 | sudo tee /proc/sys/kernel/numa_balancing >/dev/null 2>&1
}

disable_ksm() {
    echo 0 | sudo tee /sys/kernel/mm/ksm/run >/dev/null 2>&1
}

disable_turbo() {
    echo 1 | sudo tee /sys/devices/system/cpu/intel_pstate/no_turbo >/dev/null 2>&1
}

disable_nmi_watchdog() {
    echo 0 | sudo tee /proc/sys/kernel/nmi_watchdog >/dev/null 2>&1
}

flush_fs_caches() {
    echo 3 | sudo tee /proc/sys/vm/drop_caches >/dev/null 2>&1
    sleep 5
}

disable_ht() {
    echo off | sudo tee /sys/devices/system/cpu/smt/control >/dev/null 2>&1
}

bring_all_cpus_online() {
    echo 1 | sudo tee /sys/devices/system/cpu/cpu*/online >/dev/null 2>&1
}

set_performance_mode() {
    for governor in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do
        echo performance | sudo tee $governor >/dev/null 2>&1
    done
}

set_cpu_freq() {
    sudo cpupower frequency-set -u 2.1GHz >/dev/null 2>&1
}

set_perf_level() {
    echo -1 | sudo tee /proc/sys/kernel/perf_event_paranoid >/dev/null 2>&1
}

configure_cxl_exp_cores() {
    echo 1 | sudo tee /sys/devices/system/cpu/cpu*/online >/dev/null 2>&1
    echo 0 | sudo tee /sys/devices/system/node/node1/cpu*/online >/dev/null 2>&1
}

disable_va_aslr() {
    echo 0 | sudo tee /proc/sys/kernel/randomize_va_space >/dev/null 2>&1
}

disable_swap() {
    sudo swapoff -a
}

create_huge_pages_local_numa() {
    echo 1 | sudo tee /sys/devices/system/node/node0/hugepages/hugepages-1048576kB/nr_hugepages >/dev/null 2>&1
    echo 1 | sudo tee /sys/devices/system/node/node1/hugepages/hugepages-1048576kB/nr_hugepages >/dev/null 2>&1
}

create_huge_pages_cxl() {
    echo 1 | sudo tee /sys/devices/system/node/node2/hugepages/hugepages-1048576kB/nr_hugepages >/dev/null 2>&1
}

run_pmqos() {
    nohup sudo /proj/nestfarm-PG0/proj/run/pmqos &
    disown
}

check_cxl_conf() {
    set_performance_mode
    set_cpu_freq
    set_perf_level
    disable_nmi_watchdog
    disable_va_aslr
    disable_ksm
    disable_numa_balancing
    disable_thp
    disable_ht
    disable_turbo
    disable_swap
    configure_cxl_exp_cores
    create_huge_pages_local_numa
    create_huge_pages_cxl
    run_pmqos
    flush_fs_caches
}

check_conf() {
    set_performance_mode
    set_cpu_freq
    set_perf_level
    disable_nmi_watchdog
    disable_va_aslr
    disable_ksm
    disable_numa_balancing
    disable_thp
    disable_ht
    disable_turbo
    disable_swap
    configure_cxl_exp_cores
    create_huge_pages_local_numa
    run_pmqos
    flush_fs_caches
}
