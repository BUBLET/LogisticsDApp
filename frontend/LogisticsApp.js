import React, { useState, useEffect } from 'react';
import Web3 from 'web3';
import LogisticsContract from 'D:/Мисис/blockchain_kr/contracts/Logistics.sol';

function LogisticsApp() {
  const [web3, setWeb3] = useState(null);
  const [contract, setContract] = useState(null);
  const [accounts, setAccounts] = useState([]);
  const [orderCount, setOrderCount] = useState(0);
  const [reviewCount, setReviewCount] = useState(0);
  const [newOrder, setNewOrder] = useState({
    recipient: '',
    distance: 0,
    cargoType: '',
    price: 0
  });
  const [newReview, setNewReview] = useState({
    orderId: 0,
    comment: '',
    rating: 1
  });

  useEffect(() => {
    async function initWeb3() {
      try {
        // Инициализируем подключение к Ethereum-узлу
        const web3 = new Web3(Web3.givenProvider || 'http://127.0.0.1:8545');
        setWeb3(web3);

        // Получаем список доступных аккаунтов
        const accounts = await web3.eth.getAccounts();
        setAccounts(accounts);

        // Подключаемся к смарт-контракту Logistics
        const networkId = await web3.eth.net.getId();
        const deployedNetwork = LogisticsContract.networks[networkId];
        const instance = new web3.eth.Contract(
          LogisticsContract.abi,
          deployedNetwork && deployedNetwork.address
        );
        setContract(instance);

        // Получаем количество заказов и отзывов
        const orderCount = await instance.methods.getOrderCount().call();
        setOrderCount(orderCount);
        const reviewCount = await instance.methods.getReviewCount().call();
        setReviewCount(reviewCount);
      } catch (error) {
        console.error('Ошибка при инициализации Web3:', error);
      }
    }
    initWeb3();
  }, []);

  const handleAddOrder = async () => {
    try {
      await contract.methods
        .addOrder(newOrder.recipient, newOrder.distance, newOrder.cargoType, newOrder.price)
        .send({ from: accounts[0] });
      setOrderCount(orderCount + 1);
      setNewOrder({
        recipient: '',
        distance: 0,
        cargoType: '',
        price: 0
      });
    } catch (error) {
      console.error('Ошибка при добавлении заказа:', error);
    }
  };

  const handleCompleteOrder = async () => {
    try {
      await contract.methods
        .completeOrder(newReview.orderId, newReview.comment, newReview.rating)
        .send({ from: accounts[0], value: web3.utils.toWei(newReview.price.toString(), 'ether') });
      setReviewCount(reviewCount + 1);
      setNewReview({
        orderId: 0,
        comment: '',
        rating: 1
      });
    } catch (error) {
      console.error('Ошибка при выполнении заказа:', error);
    }
  };

  return (
    <div>
      <h1>Logistics App</h1>
      <h2>Заказы</h2>
      <div>
        <label htmlFor="recipient">Получатель:</label>
        <input
          id="recipient"
          type="text"
          value={newOrder.recipient}
          onChange={(e) => setNewOrder({ ...newOrder, recipient: e.target.value })}
        />
        <label htmlFor="distance">Расстояние:</label>
        <input
          id="distance"
          type="number"
          value={newOrder.distance}
          onChange={(e) => setNewOrder({ ...newOrder, distance: e.target.value })}
        />
        <label htmlFor="cargoType">Тип груза:</label>
        <input
          id="cargoType"
          type="text"
          value={newOrder.cargoType}
          onChange={(e) => setNewOrder({ ...newOrder, cargoType: e.target.value })}
        />
        <label htmlFor="price">Цена:</label>
        <input
          id="price"
          type="number"
          value={newOrder.price}
          onChange={(e) => setNewOrder({ ...newOrder, price: e.target.value })}
        />
        <button onClick={handleAddOrder}>Добавить заказ</button>
      </div>
      <h2>Отзывы</h2>
      <div>
        <label htmlFor="orderId">ID заказа:</label>
        <input
          id="orderId"
          type="number"
          value={newReview.orderId}
          onChange={(e) => setNewReview({ ...newReview, orderId: e.target.value })}
        />
        <label htmlFor="comment">Комментарий:</label>
        <input
          id="comment"
          type="text"
          value={newReview.comment}
          onChange={(e) => setNewReview({ ...newReview, comment: e.target.value })}
        />
        <label htmlFor="rating">Оценка:</label>
        <input
          id="rating"
          type="number"
          min="1"
          max="5"
          value={newReview.rating}
          onChange={(e) => setNewReview({ ...newReview, rating: e.target.value })}
        />
        <button onClick={handleCompleteOrder}>Оставить отзыв</button>
      </div>
      <p>Количество заказов: {orderCount}</p>
      <p>Количество отзывов: {reviewCount}</p>
    </div>
  );
}

export default LogisticsApp;