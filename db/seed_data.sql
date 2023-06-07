INSERT INTO users (name, password)
VALUES 
('admin', '$2a$12$i0v.IElC.H.8sKuIzEd00OhdXxAHwHCs8jVtCC8aC4A1qIEdvgIQW'); -- password is 'secret'

INSERT INTO watchlists (name, user_id)
VALUES
('Fitness', 1),
('Music', 1),
('Cooking', 1),
('Rewatch', 1),
('Watch with Family', 1),
('Watch with Friends', 1),
('Anime', 1),
('Documentaries', 1),
('Horror', 1),
('Romance', 1),
('Comedy', 1);

INSERT INTO media (name, platform, url, watchlist_id)
VALUES
('3 Fitness Tips that are NOT So Helpful - PictureFit', 'YouTube', 'https://www.youtube.com/watch?v=l93XQBRlOL4&ab_channel=PictureFit', 1),
('Protein Bar Review - LBP', 'Youtube', 'https://www.youtube.com/watch?v=tluGFwwAgfs&ab_channel=LeanBeefPatty', 1),
('Progressive Overload - PictureFit', 'Youtube', 'https://www.youtube.com/watch?v=HiJ1uLuTNxo&ab_channel=PictureFit', 1),
('FFXIV OST - Athena, The Tireless One', 'YouTube', 'https://www.youtube.com/watch?v=pKt0Gpx6NFo&ab_channel=dudewhereismyspoon', 2),
('Pokemon TCG OST', 'YouTube', 'https://www.youtube.com/watch?v=YP4uFEmNQTw&ab_channel=RareOSTs', 2),
('Sada/Turo Battle - Retro Remix', 'YouTube', 'https://www.youtube.com/watch?v=U92u5E2xZWs&ab_channel=MissCardiac', 2),
('Famitracker G/S/C Rival Battle', 'YouTube', 'https://www.youtube.com/watch?v=mdruJyio-fw&ab_channel=AtomicJosuke', 2),
('Arnold Palmer Tournament Golf - BGM 4', 'YouTube', 'https://www.youtube.com/watch?v=B0k-plfOBxw&ab_channel=DendyLegend-RetroGameMusicandSoundtrack', 2),
('I Really Want to Stay at Your House - SilvaGunner', 'YouTube', 'https://www.youtube.com/watch?v=k0MY6MDrkgY&ab_channel=SiIvaGunner', 2),
('Japanese Denim', 'YouTube', 'https://www.youtube.com/watch?v=FG2PgVl0Nlc&ab_channel=Beautiful.co.il', 2),
('the end - KFAD - SilvaGunner', 'YouTube', 'https://www.youtube.com/watch?v=GydXuedDTnQ&ab_channel=SiIvaGunner', 2),
('Moonlight Serendipity - SilvaGunner', 'YouTube', 'https://www.youtube.com/watch?v=9jq0X2CF-vA&ab_channel=SiIvaGunner', 2),
('Finally Speedrunning - SilvaGunner', 'YouTube', 'https://www.youtube.com/watch?v=XRr5GMdZsZM&ab_channel=SiIvaGunner', 2),
('Those Who Fight', 'YouTube', 'https://www.youtube.com/watch?v=n_1Bb-4aGq8&ab_channel=Cateen%E3%81%8B%E3%81%A6%E3%81%83%E3%82%93', 2),
('FE3H - God Shattering Star', 'YouTube', 'https://www.youtube.com/watch?v=fhWhTbe3MWk&ab_channel=FamilyJules', 2),
('Pop Culture', 'YouTube', 'https://www.youtube.com/watch?v=lTx3G6h2xyA&ab_channel=Madeon', 2),
('Shelter', 'YouTube', 'https://www.youtube.com/watch?v=fzQ6gRAEoy0&ab_channel=PorterRobinson', 2),
('dullscythe', 'YouTube', 'https://www.youtube.com/watch?v=oKMNj8v2gKE&ab_channel=PorterRobinson', 2),
('Revolving', 'YouTube', 'https://www.youtube.com/watch?v=f6fmuegxGO0&ab_channel=YUNGBAE', 2),
('It just is', 'YouTube', 'https://www.youtube.com/watch?v=oBpaB2YzX8s&ab_channel=eaJ', 2),
('snow-fi hip hop beats to halate to - SilvaGunner', 'YouTube', 'https://www.youtube.com/watch?v=LXQAMOd3Kww&ab_channel=SiIvaGunner', 2),
('Appalachian Snow - SilvaGunner', 'YouTube', 'https://www.youtube.com/watch?v=OTu6FaJAy9g&ab_channel=SiIvaGunner', 2),
('Neath Dark Waters & Rain', 'YouTube', 'https://www.youtube.com/watch?v=EcRubiF1TvI&ab_channel=JaxomNautilus', 2),
('Neath Dark Waters Lo-fi', 'YouTube', 'https://www.youtube.com/watch?v=qyupzA-JacA&ab_channel=Dutyyaknow', 2),
('Smile Bomb/Gurenge/Giorno''s Theme', 'YouTube', 'https://www.youtube.com/watch?v=UN4m-UgmxtM&ab_channel=J-MUSICEnsemble', 2),
('Tortilla Chip Sombrero - Babish', 'YouTube', 'https://www.youtube.com/watch?v=D_Y18GEjfNY&ab_channel=BabishCulinaryUniverse', 3),
('BBQ Showdown', 'Netflix', 'https://www.netflix.com/watch/81496341', 3),
('Great British Bakeoff', 'Netflix', 'https://www.netflix.com/watch/81608912', 3),
('Dr. Seuess Baking Challenge', 'Amazon Prime Video', 'https://www.amazon.com/gp/video/detail/B0B6RD7QCN', 3);