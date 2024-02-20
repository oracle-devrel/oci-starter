package com.example.demo;
  
import com.oracle.nosql.spring.data.repository.NosqlRepository;

interface DemoRepository extends NosqlRepository<Dept, Long> {
    DemoRepository() {
        try {
            System.out.println("Preloading " + repository.save(new Dept(10, "ACCOUNTING", "BRUSSELS")));
            System.out.println("Preloading " + repository.save(new Dept(20, "RESEARCH", "SPRING NOSQL")));
            System.out.println("Preloading " + repository.save(new Dept(30, "SALES", "ROME")));
            System.out.println("Preloading " + repository.save(new Dept(40, "OPERATIONS", "MADRID")));    
        } catch (Exception e ) {
            System.err.println("Exception:" + e.getMessage());
            e.printStackTrace();
        }              
    }
}