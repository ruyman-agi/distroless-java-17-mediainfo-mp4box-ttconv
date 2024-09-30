FROM python:3.12.6-slim-bookworm AS python-builder
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir --pre ttconv
FROM registry.agilecontent.com/docker/distroless-java-17/main:latest
COPY --from=python-builder /lib /lib
COPY --from=python-builder /lib64 /lib64
COPY --from=python-builder /usr/local/bin /usr/local/bin
COPY --from=python-builder /usr/local/lib /usr/local/lib
ENV PYTHONPATH="/usr/local/lib/python3.12/site-packages/ttconv:$PYTHONPATH"
