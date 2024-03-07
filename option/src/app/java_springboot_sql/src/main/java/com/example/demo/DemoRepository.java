package com.example.demo;
  
import org.springframework.data.jpa.repository.JpaRepository;

interface DemoRepository extends JpaRepository<Dept, Long> {
}
