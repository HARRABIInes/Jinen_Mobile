const axios = require('axios');

const API = 'http://localhost:3000/api';

async function run() {
  try {
    // Ensure we have a parent user (register or login)
    const email = 'test_parent@example.com';
    const password = 'password123';
    let parentId = null;

    // Try login
    console.log('Step: login/register');
    try {
      const login = await axios.post(`${API}/auth/login`, { email, password });
      if (login.data && login.data.success) parentId = login.data.user.id;
      console.log('Login successful, parentId:', parentId);
    } catch (e) {
      console.log('Login failed, attempting register');
      try {
        const reg = await axios.post(`${API}/auth/register`, { email, password, name: 'Test Parent', user_type: 'parent' });
        parentId = reg.data.user.id;
        console.log('Registered parentId:', parentId);
      } catch (re) {
        console.error('Register failed:', re.response ? re.response.data : re.message);
        throw re;
      }
    }

    // Get a nursery
    const nurResp = await axios.get(`${API}/nurseries`);
    if (!nurResp.data.success || nurResp.data.nurseries.length === 0) throw new Error('No nurseries');
    const nurseryId = nurResp.data.nurseries[0].id;
    console.log('Using nursery:', nurseryId);

    // Create review
    console.log('Step: create review');
    let reviewId = null;
    try {
      const create = await axios.post(`${API}/nurseries/${nurseryId}/reviews`, { parentId, rating: 4.5, comment: 'Test review' });
      console.log('Create response:', create.data);
      reviewId = create.data.review.id;
    } catch (ce) {
      console.error('Create failed:', ce.response ? ce.response.data : ce.message);
      throw ce;
    }

    // Get reviews
    const list = await axios.get(`${API}/nurseries/${nurseryId}/reviews`);
    console.log('Reviews count:', list.data.reviews.length);

    // Edit review
    console.log('Step: edit review');
    try {
      const edit = await axios.put(`${API}/reviews/${reviewId}`, { parentId, rating: 3.5, comment: 'Edited test review' });
      console.log('Edit response:', edit.data);
    } catch (ee) {
      console.error('Edit failed:', ee.response ? ee.response.data : ee.message);
      throw ee;
    }

    // Delete review
    console.log('Step: delete review');
    try {
      const del = await axios.delete(`${API}/reviews/${reviewId}`, { data: { parentId } });
      console.log('Delete response:', del.data);
    } catch (de) {
      console.error('Delete failed:', de.response ? de.response.data : de.message);
      throw de;
    }

    console.log('Test sequence completed successfully');
  } catch (err) {
    console.error('Test failed:', err.response ? err.response.data : err.stack || err.message);
  }
}

run();
