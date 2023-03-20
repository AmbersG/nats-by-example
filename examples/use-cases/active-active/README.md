# Active Active

An active-active stream is typically used for
multi-region deployments where failover is desired.

There are two possible setups with active-active.

1. A primary region where all client connections and
   traffic directed at a stream in region A will transparently fail
   over to an *active replica* in region B.

   From the client's perspective, there is continuity between these
   regions.

   If region A recovers, it may be preferred that the clients switch
   back to region A especially to reduce latency.

2. Another setup may involve multiple regions each serving their own
   set of clients, naturally partitioned by their geography. If a
   given region becomes unvailable, those clients could failover to
   a healthy region.

## Current limitations

- A stream by the same name cannot exist within the same account
  even if placed on different clusters. By convention, each stream
  should have a suffix, e.g. `events-west` and `events-east` to
  differentiate where they exist.
- Although a two streams can bi-directionally source from one
  another, the subjects cannot be homogenized since each streams
  under the same account cannot have overlapping subjects. In
  addition, bi-directional sourcing with homogenizing the subjects
  would lead to a loop.
- There are no concept of consumer mirrors which means on a failover,
  consumers will need to be recreated with the last known sequence.
  This is feasible, however any message re-delivery state in the
  consumer will be lost. On failover, clients would need to set the
  sequence number to the earliest non-acked message and need to handle
  later messages that may have been processed already.

## Possible improvements

- Formalize active-active streams by having clients that connect
  to the cluster that a stream exists on to implicitly direct all
  writes there.

- In the case where the stream/cluster/region becomes unavailable
  clients connect to another cluster and continue appending/
  consuming from the local stream.

## Assumptions

- Two or more regions
- A stream per region each sourcing from one another.

## Client responsibility

- Be aware of all cluster (region) endpoints
- Connect to the preferred cluster
- Each stream will have its own subject prefix corresponding to the cluster
- A client should publish to the stream with `Nats-Msg-Id` for dedupe
  and always check for acks for sync and async publishing.
- For each consumer a client creates, it must maintain the current
  stream ack floor sequence number
- An `AckAck` may be desirable if idempotent handling of messages
  is problematic on the client-side
- When a failover is triggered, which may be automatic given some
  failure detection mechanism or manually performed, the client must
  reconnect to healthy cluster, swap the stream name and subject
  prefix (for publishing) and bootstrap the consumers.
- Since the new local stream may be lagging in replication, it is
  possible that a consumers ack floor is greater than the stream
  sequence number. This implies the client observed a message in the
  other cluster that was not yet replicated to this cluster. This also
  implies that publishing to this stream in this state will result
  in streams with potentially different ordering once the existing
  cluster becomes healthy. This may be mitigated by deduplication.