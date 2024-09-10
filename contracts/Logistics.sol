// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2 <0.9.0;

contract Logistics {

// Структура для хранения информации о заказе
struct Order {
    address sender; // Адрес отправителя
    address recipient; // Адрес получателя
    uint distance; // Расстояние между пунктами отправления и назначения
    string cargoType; // Тип груза
    uint price; // Стоимость заказа
    bool isCompleted; // Флаг, указывающий на то, выполнен ли заказ
    bool isCancelled; // Флаг, указывающий, отменен ли заказ
    uint escrow; // Хранение средств в контракте до завершения заказа
}

// Структура для хранения информации об изменениях заказа
struct OrderChange {
    uint orderId; // Идентификатор заказа
    string changeDescription; // Описание изменения
    uint timestamp; // Время изменения
}

// Структура для хранения информации об отзыве
struct Review {
    uint orderId; // Идентификатор заказа, к которому относится отзыв
    address reviewer; // Адрес участника, оставившего отзыв
    string comment; // Текст отзыва
    uint rating; // Оценка выполнения заказа от 1 до 5
}

// Массивы для хранения всех заказов, отзывов и изменений
Order[] public orders;
Review[] public reviews;
OrderChange[] public orderChanges;

// Мероприятие для отслеживания изменений заказов
event OrderChanged(uint orderId, string changeDescription, uint timestamp);
event OrderAdded(uint orderId, address sender, address recipient, uint price);

// Функция для добавления нового заказа
function addOrder(address _recipient, uint _distance, string memory _cargoType, string memory _price) public payable {
    require(_recipient != msg.sender, "Sender and recipient cannot be the same person");
    // Конвертируем строку в uint
    uint price = parseUint(_price); 
    require(msg.value == price, "Sent Ether does not match the price of the order");

    // Добавляем заказ и сохраняем средства на контракте
    orders.push(Order(msg.sender, _recipient, _distance, _cargoType, price, false, false, msg.value));
    emit OrderAdded(orders.length - 1, msg.sender, _recipient, price);
}

// Вспомогательная функция для конвертации строки в uint
function parseUint(string memory _value) internal pure returns (uint) {
    bytes memory bytesValue = bytes(_value);
    uint result = 0;
    for (uint i = 0; i < bytesValue.length; i++) {
        result = result * 10 + (uint(uint8(bytesValue[i])) - 48);
    }
    return result;
}



// Функция для выполнения заказа и оставления отзыва
function completeOrder(uint _orderId, string memory _comment, uint _rating) public payable {
    require(msg.sender == orders[_orderId].recipient, "Only the recipient can finalize an order");
    require(!orders[_orderId].isCompleted, "The order has already been placed");
    require(!orders[_orderId].isCancelled, "The order was canceled");

    orders[_orderId].isCompleted = true;
    payable(orders[_orderId].sender).transfer(orders[_orderId].escrow); // Перевод стоимости заказа отправителю

    // Добавляем новый отзыв
    reviews.push(Review(_orderId, msg.sender, _comment, _rating));
}

// Функция для отмены заказа
function cancelOrder(uint _orderId) public {
    require(msg.sender == orders[_orderId].sender, "Only the sender can cancel an order");
    require(!orders[_orderId].isCompleted, "You cannot cancel a completed order");

    orders[_orderId].isCancelled = true;
    
    // Возвращаем средства отправителю при отмене заказа
    payable(orders[_orderId].sender).transfer(orders[_orderId].escrow);

    // Добавляем запись об изменении заказа
    addOrderChange(_orderId, "The order was canceled");
}

// Функция для добавления изменений заказа
function addOrderChange(uint _orderId, string memory _changeDescription) internal {
    orderChanges.push(OrderChange(_orderId, _changeDescription, block.timestamp));
    emit OrderChanged(_orderId, _changeDescription, block.timestamp);
}

// Функция для получения изменений заказа
function getOrderChanges(uint _orderId) public view returns (OrderChange[] memory) {
    uint changeCount = 0;

    // Подсчитываем количество изменений для конкретного заказа
    for (uint i = 0; i < orderChanges.length; i++) {
        if (orderChanges[i].orderId == _orderId) {
            changeCount++;
        }
    }

    // Создаем массив для изменений заказа
    OrderChange[] memory changes = new OrderChange[](changeCount);
    uint index = 0;

    for (uint i = 0; i < orderChanges.length; i++) {
        if (orderChanges[i].orderId == _orderId) {
            changes[index] = orderChanges[i];
            index++;
        }
    }

    return changes;
}

// Функция для получения количества заказов в системе
function getOrderCount() public view returns (uint) {
    return orders.length;
}

// Функция для получения количества отзывов в системе
function getReviewCount() public view returns (uint) {
    return reviews.length;
}

// Функция для получения отзывов по определенному заказу
function getReviewsByOrder(uint _orderId) public view returns (Review[] memory) {
    uint reviewCount = 0;

    // Подсчитываем количество отзывов для конкретного заказа
    for (uint i = 0; i < reviews.length; i++) {
        if (reviews[i].orderId == _orderId) {
            reviewCount++;
        }
    }

    // Создаем массив для отзывов по заказу
    Review[] memory orderReviews = new Review[](reviewCount);
    uint index = 0;

    for (uint i = 0; i < reviews.length; i++) {
        if (reviews[i].orderId == _orderId) {
            orderReviews[index] = reviews[i];
            index++;
        }
    }

    return orderReviews;
}

// Функция для получения заказов с пагинацией
function getOrders(uint startIndex, uint endIndex) public view returns (Order[] memory) {
    require(endIndex >= startIndex, "End index must be greater than or equal to start index");
    require(endIndex < orders.length, "End index out of bounds");

    uint length = endIndex - startIndex + 1;
    Order[] memory orderList = new Order[](length);

    for (uint i = 0; i < length; i++) {
        orderList[i] = orders[startIndex + i];
    }

    return orderList;
}


}

