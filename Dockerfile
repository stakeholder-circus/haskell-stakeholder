FROM debian:bookworm-slim AS build
RUN apt-get update && apt-get install -y --no-install-recommends ca-certificates curl build-essential ghc cabal-install libgmp-dev zlib1g-dev && rm -rf /var/lib/apt/lists/*
WORKDIR /src
COPY . .
RUN cabal update
RUN cabal build all
RUN cabal test all
RUN mkdir -p /out && cabal install exe:haskell-stakeholder --install-method=copy --installdir=/out --overwrite-policy=always

FROM debian:bookworm-slim AS runtime
RUN apt-get update && apt-get install -y --no-install-recommends libgmp10 && rm -rf /var/lib/apt/lists/*
COPY --from=build /out/haskell-stakeholder /usr/local/bin/haskell-stakeholder
ENTRYPOINT ["/usr/local/bin/haskell-stakeholder"]
