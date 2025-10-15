import http from 'k6/http';
import { sleep } from 'k6';

export let options = {
  vus: 50,            // 20 virtual users
  duration: '60s',    // run for 1 minute
};

export default function () {
  http.get('http://localhost:5000/api/college/get-colleges');
  sleep(1);
}
