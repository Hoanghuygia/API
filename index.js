const express = require('express');
const morgan = require('morgan');

const app = express();


app.use(morgan('combined'));


app.listen(3000, () => {
    console.log("Using port 3000");
})