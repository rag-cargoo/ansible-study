import http from 'k6/http';
import { sleep, check } from 'k6';

export const options = {
  stages: [
    { duration: '30s', target: 20 }, // ramp up to 20 users over 30s
    { duration: '1m', target: 20 },  // stay at 20 users for 1m
    { duration: '10s', target: 0 },   // ramp down to 0 users
  ],
};

export default function () {
  const res = http.get('http://10.0.101.10:8000');
  check(res, { 'status was 200': (r) => r.status == 200 });
  sleep(1);
}
