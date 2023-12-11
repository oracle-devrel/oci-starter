package com.example;

import io.micronaut.data.annotation.Repository;
import io.micronaut.data.repository.CrudRepository;

import javax.persistence.EntityManager;
import java.util.List;

@Repository
public abstract class DeptRepository implements CrudRepository<Dept, Long> {

    private final EntityManager entityManager;

    public DeptRepository(EntityManager entityManager) {
        this.entityManager = entityManager;
    }

    public List<Dept> find() {
        return entityManager.createQuery("FROM Dept AS dept", Dept.class)
                    .getResultList();
    }
}