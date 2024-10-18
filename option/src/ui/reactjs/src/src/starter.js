import React, { useState, useEffect } from "react";
import AppBar from '@mui/material/AppBar';
import Box from '@mui/material/Box';
import Toolbar from '@mui/material/Toolbar';
import Typography from '@mui/material/Typography';
import Button from '@mui/material/Button';
import IconButton from '@mui/material/IconButton';
import MenuIcon from '@mui/icons-material/Menu';
import Table from '@mui/material/Table';
import TableBody from '@mui/material/TableBody';
import TableCell from '@mui/material/TableCell';
import Container from '@mui/material/Container';
import TableHead from '@mui/material/TableHead';
import TableRow from '@mui/material/TableRow';

import axios from "axios";

function createData(deptno, dname, loc) {
    return { deptno, dname, loc };
}

const rows = [];

export default function Starter() {
    const [data, setData] = useState([]);

    useEffect(() => {
        axios
            .get("app/dept")
            .then((res) => {
                setData(res.data);
                var json = document.getElementById("json");
                if (json != null) {
                    json.innerHTML = JSON.stringify(res.data);
                }
                console.log("Json:", data);
            })
            .catch((error) => {
                console.log(error);
            });
        axios
            .get("app/info")
            .then((res) => {
                var info = document.getElementById("info");
                if (info != null) {
                    info.innerHTML = res.data;
                }
                console.log("Info:", data);
            })
            .catch((error) => {
                console.log(error);
            });
    }, []);

    return (
        <div>
            <Box sx={{ flexGrow: 1 }}>
                <AppBar position="static">
                    <Toolbar>
                        <IconButton
                            size="large"
                            edge="start"
                            color="inherit"
                            aria-label="menu"
                            sx={{ mr: 2 }}
                        >
                            <MenuIcon />
                        </IconButton>
                        <Typography variant="h6" component="div" sx={{ flexGrow: 1 }}>
                            OCI Starter
                        </Typography>
                        <Button color="inherit">ReactJS</Button>
                    </Toolbar>
                </AppBar>
            </Box>
            <Container style={{ marginLeft: "0px" }}>
                <br></br>
                <Typography variant="h3">Sample</Typography>
                <br></br>
                <Typography variant="h5">Rest Result</Typography>
                <div id="json"></div>
                <br></br>
                <Typography variant="h5">Department Table</Typography>

                <Table sx={{ maxWidth: 650 }} size="small" aria-label="a dense table">
                    <TableHead>
                        <TableRow>
                            <TableCell align="right">Number</TableCell>
                            <TableCell align="right">Name</TableCell>
                            <TableCell align="right">Location</TableCell>
                        </TableRow>
                    </TableHead>
                    <TableBody>
                        {data.map((row) => (
                            <TableRow
                                key={row.deptno}
                                sx={{ '&:last-child td, &:last-child th': { border: 0 } }}
                            >
                                <TableCell align="right">{row.deptno}</TableCell>
                                <TableCell align="right">{row.dname}</TableCell>
                                <TableCell align="right">{row.loc}</TableCell>
                            </TableRow>
                        ))}
                    </TableBody>
                </Table>
                <br></br>
                <Typography variant="h5">Rest Info</Typography>
                <div id="info"></div>
            </Container>
        </div>
    );
}

