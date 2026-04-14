# DNS Benchmark for Romania (Bash)

A small Bash script that benchmarks public DNS resolvers from a Romanian public DNS list and compares them with the DNS servers you currently use in OpenWrt.

It was written for Linux Mint / Debian-based systems and focuses on a practical workflow:
- pull a shorter public DNS list from `wlog.ro`
- add your current upstream public DNS servers manually
- test resolver latency with `dig`
- show live progress in the terminal
- append results to a history file so you can compare performance over time

## What the script does

The script:
- downloads a public DNS source page from `https://wlog.ro/public-dns.php`
- extracts IPv4 DNS servers from that page
- adds your current public DNS servers (for example the upstream DNS configured in OpenWrt)
- tests each server against a chosen domain using `dig`
- calculates average latency in milliseconds
- shows progress live in the terminal
- writes the fastest DNS servers to `fastest-dns-ro.txt`
- appends a dated result block at the end of the same file so you can track changes over time

## Why manual current DNS values are used

On many Linux systems, the local machine only sees:
- a local stub resolver
- the router IP
- or a LAN DNS address

That is often **not** the real upstream public DNS used by OpenWrt.

Because of that, the script allows you to define your real current public DNS manually in:

```bash
CURRENT_PUBLIC_DNS=(
    "109.166.202.230"
    "109.166.202.220"
)
```

This makes the comparison more accurate.

## Requirements

Install:

```bash
sudo apt update
sudo apt install dnsutils curl
```

`dnsutils` provides `dig`.

## Usage

Make the script executable:

```bash
chmod +x dnsbench_ro.sh
```

Run it:

```bash
./dnsbench_ro.sh
```

## Output

The script appends results to:

```text
fastest-dns-ro.txt
```

Each run adds:
- date and time
- source URL
- tested domain
- number of queries per DNS
- current public DNS and their measured latency
- top fastest DNS servers
- `resolv.conf`-style output for quick reuse

## Settings you may want to change

These values are near the top of the script.

### 1. Domain used for testing

```bash
DOMAIN="etools.ch"
```

You can replace it with another domain such as:
- `example.com`
- a local favorite site
- a domain you query often
- a stable domain with good global availability

For more relevant results, use a domain that is close to your real browsing or service usage pattern.

### 2. Number of queries per DNS

```bash
COUNT=3
```

This controls how many test queries are sent to each DNS server.

- lower value, faster run, less stable average
- higher value, slower run, more stable average

Suggested values:
- `1` for a very fast test
- `3` as a good default
- `5` or more for more consistent results

### 3. How many servers are shown in the top

```bash
TOP=3
```

Change this if you want a bigger shortlist.

Examples:
- `TOP=3`
- `TOP=5`
- `TOP=10`

### 4. Public DNS source list

```bash
URL="https://wlog.ro/public-dns.php"
```

This is the page used as the public DNS source.

It was chosen because it is shorter and more practical than very large public DNS lists.

If you want, you can replace it with another source, but then you may also need to adapt the extraction logic.

### 5. Your current public DNS servers

```bash
CURRENT_PUBLIC_DNS=(
    "109.166.202.230"
    "109.166.202.220"
)
```

Set these to the real upstream public DNS values configured in your OpenWrt router.

## Notes on relevance

DNS benchmark results can vary depending on:
- time of day
- packet loss
- route changes
- caching
- the domain being tested
- filtering features on the resolver side

For more meaningful comparisons:
- run the script several times during the day
- keep the same test domain for a while
- compare averages across multiple runs
- test with `COUNT=3` or `COUNT=5`
- keep your current DNS in the benchmark list

## Example workflow

1. Set your current OpenWrt upstream DNS in `CURRENT_PUBLIC_DNS`
2. Choose a representative domain in `DOMAIN`
3. Run the script
4. Check `fastest-dns-ro.txt`
5. Compare current DNS vs top candidates
6. Update OpenWrt if needed
7. Run the script again later and compare history

## Terminal behavior

The script shows live progress in the terminal, including:
- which DNS is currently being tested
- average latency for that resolver
- timeout information
- a progress bar

## Possible future improvements

Ideas you may want to add later:
- multiple test domains and combined score
- filtering only non-blocking resolvers
- parallel testing for faster runs
- CSV export
- rank tracking between runs
- automatic OpenWrt DNS retrieval over SSH

## License

Use, modify, and publish as you like.

If you upload it to GitHub, you may also want to add an explicit license such as MIT.
