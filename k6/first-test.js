import http from 'k6/http';

import { sleep } from 'k6';

export const options = {
    vus: 100,
    duration: '100s'
};

export default function () {
    let url = 'http://app.mishap.local';
    // let port = '5400'
    let search_path = '/rapid_api_search'
    let root_path = '/'
    let test_path = '/test'
    let paths = [search_path, root_path, test_path]
    
    for (let path of paths) {
        http.get(url + path);
        console.log(url + path)
        sleep(0.3)
    }
}

// command to run: k6 run k6-test.js --insecure-skip-tls-verify