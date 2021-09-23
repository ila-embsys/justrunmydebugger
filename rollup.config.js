// rollup.config.js
import json from '@rollup/plugin-json';
import { nodeResolve } from '@rollup/plugin-node-resolve';
import commonjs from '@rollup/plugin-commonjs';
import html from '@open-wc/rollup-plugin-html';
import replace from '@rollup/plugin-replace';
import fs from 'fs';
import path from 'path';
import styles from "rollup-plugin-styles";

export default {
    input: 'src/main.bs.js',
    output: {
        dir: 'dist',
        format: 'es'
    },
    plugins: [
        json(),
        nodeResolve(),
        commonjs(),
        html({
            template() {
                return new Promise((resolve) => {
                    const indexPath = path.join(__dirname, 'src', 'index.html');
                    fs.readFile(indexPath, 'utf-8', (err, data) => {
                        resolve(data);
                    });
                })
            }
        }),
        replace({
            'process.env.NODE_ENV': JSON.stringify('production'),
            'preventAssignment': true
        }),
        styles()
    ]
};
