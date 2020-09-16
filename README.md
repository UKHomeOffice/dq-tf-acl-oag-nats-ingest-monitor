# dq-tf-acl-sftp-monitor


These Lambdas watch S3 Buckets which lands Ingested Data for ACL, OAG and NATS. It checks to see that files are regularly being recieved.

Tasks include:
- Checking S3 at selected intervals
- Checking if a file has arrived within a the specified period
- If a file has a arrived within specified period, it notes the last file received
- If a file has a NOT arrived within specified period, A Slack alert is generated


## ACL

- **acl-data-ingest-monitor-notprod-lambda**
  - *dq-acl-data-ingest*: This is the Kube Pod which gets from remote SFTP Server
  - *s3-dq-acl-archive-notprod*: This is the monitored bucket which *dq-acl-data-ingest* lands ingested data.
  - *Root Directory/*: The path monitored for update timestamps.
  - *Once a Day (Midnight)*: This file arrives once a day.
  - *28 Hours*: The expected time period a file should arrive is 24hours. An extra 4 hours is given before a     Slack alert is generated.


## OAG

- **oag-data-ingest-monitor-notprod-lambda**
  - *dq-oag-data-ingest*: This is the Kube Pod which gets from remote SFTP Server
  - *s3-dq-oag-archive-notprod*: This is the monitored bucket which *dq-oag-data-ingest* lands ingested data.
  - *Root Directory/*: The path monitored for update timestamps.
  - *Once a Minute*: This file arrives roughly every minute.
  - *15 minutes*: The expected time period a file should arrive is every minute. An extra 14 minutes is given before a Slack alert is generated.

## NATS

- **nats-data-ingest-monitor-notprod-lambda**
  - *dq-nats-data-ingest*: This is the Kube Pod which gets from remote SFTP Server
  - *s3-dq-nats-archive-notprod*: This is the monitored bucket which *dq-nats-data-ingest* lands ingested data.
  - *<YYYY>/<MM>/<DD>/*: The path monitored for update timestamps.
  - *Once 4 Minutes*: This file arrives roughly every minute.
  - *15 minutes*: The expected time period a file should arrive is roughly every 4 minutes. An extra 11 minutes is given before a Slack alert is generated.
