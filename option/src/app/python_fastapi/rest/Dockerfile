FROM python:3-bookworm

RUN pip install --upgrade pip

WORKDIR /app
ENV PATH="/app/.local/bin:${PATH}"
COPY ./ /app/
RUN pip3 install -r requirements.txt

ENTRYPOINT ["python3","rest.py"]

