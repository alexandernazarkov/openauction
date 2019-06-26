pragma solidity ^0.4.22;

contract SimpleAuction {
    // Параметры аукциона. Времена либо
     // абсолютные метки времени Unix (секунды с 1970-01-01)
     // либо периоды времени в секундах.
    address public beneficiary;
    uint public auctionEnd;

    // Текущее состояние аукциона.
    address public highestBidder;
    uint public highestBid;

    // Разрешено снятие предыдущих заявок
    mapping(address => uint) pendingReturns;

    // В конце устанавливается значение true, запрещает любые изменения
    bool ended;

    // События, которые будут срабатывать при изменениях
    event HighestBidIncreased(address bidder, uint amount);
    event AuctionEnded(address winner, uint amount);

    // Ниже приведен так называемый комментарий natspec,
     // узнаваем по трем слэшам.
     // Будет показан, когда пользователя попросят
     // подтвердить транзакцию

    /// Создайте простой аукцион с `_biddingTime`
     /// секунд времени торгов от имени
     /// адреса получателя `_beneficiary`.
    constructor(
        uint _biddingTime,
        address _beneficiary
    ) public {
        beneficiary = _beneficiary;
        auctionEnd = now + _biddingTime;
    }

    /// Ставка на аукцион вместе с количеством поставленного эфира
     /// Значение будет возвращено только если
     /// аукцион не выигран
    function bid() public payable {
        // Никаких аргументов не нужно, все
         // информация уже является частью
         // транзакции. Ключевое слово "payable"
         // требуется для того, чтобы функция
         // была в состоянии получать эфир

        // Отменить вызов функции, если
         // период  торгов окончен.
        require(
            now <= auctionEnd,
            "Auction already ended."
        );

        // Если ставка не выше максимальной, отправить
         // деньги назад.
        require(
            msg.value > highestBid,
            "There already is a higher bid."
        );

        if (highestBid != 0) {
            // Отослать деньги обратно, просто используя
             // highestBidder.send(highestBid) - угроза безопасности,
             // потому что он может выполнить небезопасный контракт.
             // Всегда безопаснее позволить получателям
             // забирать свои деньги самим.
            pendingReturns[highestBidder] += highestBid;
        }
        highestBidder = msg.sender;
        highestBid = msg.value;
        emit HighestBidIncreased(msg.sender, msg.value);
    }

    /// Возвращаем ставку, если она была перебита
    function withdraw() public returns (bool) {
        uint amount = pendingReturns[msg.sender];
        if (amount > 0) {
            // Важно присвоить этому ноль, потому что получатель
             // может еще раз вызвать эту функцию, что не будет являться корректным
            pendingReturns[msg.sender] = 0;

            if (!msg.sender.send(amount)) {
                pendingReturns[msg.sender] = amount;
                return false;
            }
        }
        return true;
    }

    /// Завершаем аукцион и отправляем самую высокую ставку
     /// бенефициару
    function auctionEnd() public {
        // Хорошим тоном является структурировать функции, которые взаимодействуют
         // с другими контрактами (то есть они вызывают функции или отправляют эфир)
         // в три блока:
         // 1. проверка условий
         // 2. выполнение действий (потенциально меняющих условия)
         // 3. взаимодействие с другими контрактами

        // 1. Условия
        require(now >= auctionEnd, "Auction not yet ended.");
        require(!ended, "auctionEnd has already been called.");

        // 2. Действия
        ended = true;
        emit AuctionEnded(highestBidder, highestBid);

        // 3. Взаимодействие
        beneficiary.transfer(highestBid);
    }
}
