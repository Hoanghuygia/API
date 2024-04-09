const express = require('express');
const morgan = require('morgan');
const pool = require("./db-connect");
const e = require("express");
const app = express();


app.use(morgan('combined'));
app.use(express.json());


app.get("/todos", async(req, res) =>{
    try {
        const allTodos = await pool.query("SELECT * FROM to_do;");

        res.json(allTodos.rows);
    } catch (error) {
        console.error(error.message);
    }
});

app.get("/todos/:id", async(req, res) =>{
    // console.log(req.params);
    // const { id } = req.params;
    const id = req.params.id;

    try {
        const todo = await pool.query("SELECT * FROM to_do WHERE todo_id = ($1)", [id]);

        res.json(todo.rows[0]);
    } catch (error) {
        console.error(error.message)
    }
});

app.post("/todos", async(req, res) => {
    try {
        console.log(req.body);
        const { description } = req.body;
        const newTodo = await pool.query(
            "INSERT INTO to_do(description) VALUES ($1) RETURNING *", 
            [description]
        );

        res.json(newTodo);
    } catch (err) {
       console.error(err.message);
    }
});

app.put("/todos/:id", async(req, res) =>{
    const id = req.params.id;
    try {
        const description = req.body.description;

        updateTodo = await pool.query("UPDATE to_do SET description= ($1) WHERE todo_id= ($2) RETURNING *", [description, id]);

        res.json(updateTodo);
    } catch (error) {
        console.error(error.message);
    }
})

app.delete("/todos/:id", async(req, res) => {
    const {id} = req.params;
    try {
        deleteTodo = await pool.query("DELETE FROM to_do WHERE todo_id= $1", [id]);

        res.json("DELETED");
    } catch (error) {
        console.error(error.message);
    } 
})

app.listen(3000, () => {
    console.log("server is listening port 5000");
});