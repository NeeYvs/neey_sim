CREATE TABLE `sim` (
  `phone_number` varchar(255) NOT NULL,
  `owner` varchar(255) DEFAULT NULL
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

ALTER TABLE `sim`
  ADD PRIMARY KEY (`phone_number`);
COMMIT;
