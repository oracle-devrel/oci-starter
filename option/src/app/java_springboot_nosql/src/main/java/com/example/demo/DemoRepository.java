package com.example.demo;
  
import com.oracle.nosql.spring.data.repository.NosqlRepository;

interface DemoRepository extends NosqlRepository<Dept, Long> {}