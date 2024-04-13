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



//overal.js
var express = require('express');

const {getTotalProduct} = require('./postgres');
const {getTopSellings} = require('./postgres');

var router = express.Router();

/**
 * GET-get the total product in Overal Inventory
 */
router.get('/totalProduct', async(req, res) =>{
    const totalProduct = await getTotalProduct();
    res.json(totalProduct);
})

/**
 * GET-get the top selling in Overal Inventory
 */
router.get('/topselling', async(req, res) => {
    const topselling = await getTopSellings();
    res.json(topselling);

})

module.exports = router;

//home.js
var express = require('express');

const {getCategoryNumber} = require('./postgres');
const {getOrderNumber} = require('./postgres');
const {getTotalRevenue} = require('./postgres');

var router = express.Router();

/**
 * GET - get category number in home screen
 */
router.get('/category', async(req, res) =>{

    const categoryNumber = await getCategoryNumber();
    res.json(categoryNumber);
})

/**
 * GET - get order number in home screen
 */
router.get('/order', async(req, res) =>{
    const orderNumber = await getOrderNumber();
    res.json(orderNumber);
})

/**
 * GET - get revenue number in home screen
 * this get API still wrong due to wrong query
 */
router.get('/revenue', async(req, res) =>{
    const totalRevenue = await getTotalRevenue();
    res.json(totalRevenue);
})

module.exports = router;
