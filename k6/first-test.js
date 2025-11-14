import http from 'k6/http';

import { sleep } from 'k6';

export const options = {
    vus: 1,
    duration: '10s'
};

export default function () {
    let env = 'local'
    let url = {
        local: 'http://localhost:5400',
        cloud: 'http://app.mishap.local'
    }
    let search_paths = ['/business/rapid_api_search', '/news/everything?q=Ukraine']
    
    for (let path of search_paths) {
        http.get(url[env] + path);
        console.log(url + path)
        sleep(0.3)
    }
}

// command to run: k6 run k6-test.js --insecure-skip-tls-verify