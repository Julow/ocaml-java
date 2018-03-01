FROM ocaml/ocaml:debian-stable

RUN apt-get update

# Opam

RUN apt-get install -y opam aspcud
RUN echo y | opam init

# OCaml

RUN opam switch 4.06.0
RUN opam install -y ppx_tools ocaml-migrate-parsetree

# Java

RUN apt-get install -y openjdk-8-jdk

#

ENV JAVA_HOME /usr/lib/jvm/java-8-openjdk-amd64

RUN mkdir /app
WORKDIR /app
