\echo :FILE 'in'


/**
    Aтомарное создание комнаты для новичков.
**/
drop sequence if exists seq_noobslive_room_id;
create sequence seq_noobslive_room_id;
create or replace function  mknoobsroom() returns numeric as $$
declare
     _res numeric;
begin
        select mknoobsroom((select -nextval('seq_noobslive_room_id'))) into _res;
        return _res;
end;
$$ language 'plpgsql';


create or replace function  mknoobsroom(did numeric) returns numeric as $$
declare
     _doc_id numeric;
begin
    lock table room  in exclusive mode;
        insert into doc (
            "id",
            "head",
            "body"
        ) values (
            $1,
            'head',
            'body'
        ) returning id into _doc_id;
    begin
        insert into room (
            doc_id,
            roomtype_id
        )
        values (
            _doc_id,
            (select "id" from roomtype where alias='noobs')
        );
    exception
         when unique_violation then
    end;
    return _doc_id as "id";
end;
$$ language 'plpgsql';


/**
    Тригер, который засовывает новичков в случайную комнату для новичков.
**/
create or replace function  noobsroom() returns numeric as $$
declare
     _res numeric;
begin
    select doc_id from room
        join roomtype on
            roomtype.id = room.roomtype_id
            and roomtype.alias='noobs'
            order by random() limit 1 into _res;
    if _res is null then
        perform mknoobsroom();
        select noobsroom() into _res;
        return _res;
    else
        return _res;
    end if;
end;
$$ language 'plpgsql';




/**
    @doc Возвращает начальное состояние пользователя
**/
create or replace function pers_util_fields_on_insert() returns "trigger" as $$
begin
    /**
        Статус online \ offline
    **/
    new.pstatus_alias   = 'offline';
    new.pstatus_id      =
        (select pstatus.id
            from pstatus
                where alias = new.pstatus_alias);
    /**
        Авторитет пользователя
    **/
    new.authority_alias = 'noob';
    new.authority_id    =
        (select authority.id
            from authority
                where alias = new.authority_alias);
    new.authority_level    =
        (select authority.level
            from authority
                where alias = new.authority_alias);
    /**
        Опыт пользователя
    **/
    new.exper    =
        (select authority.level
            from authority
                where alias = new.authority_alias);
    /**
        Сколько еще нужно опыта
        для перехода на следующий уровень.
    **/
    new.experlack    =
        (   select
                min(cur.level)
            from
                authority as cur
            join
                authority as prev
            on
                prev.level < cur.level
            where
                prev.alias = new.authority_alias
        ) - new.exper;

    if not (new.experlack is null) then
        new.experlackprice  = 0.5 * new.experlack;
    else
        new.experlackprice  = null;
    end if;

    /**
        Эмоции пользователя
    **/
    new.emotion_alias   = 'indifferent';
    new.emotion_id      =
        (select id from emotion   where alias = new.emotion_alias);

    /**
        Чиновничий статус пользователя
    **/
    new.ostatus_alias   = 'citizen';
    new.ostatus_id      = (select id from ostatus   where alias = new.ostatus_alias);

    /**
        Семейное положения пользователя
    **/
    new.mstatus_alias   = 'single';
    new.mstatus_id      =
        (select id from mstatus   where alias = new.mstatus_alias);
    /**
        Язык пользователя
    **/
    new.lang_alias      = 'en_gb';
    new.lang_id         =
        (select id from lang      where alias = new.lang_alias);

    new.live_room_id         = (select noobsroom());
    new.live_room_head       =
        (select doc.head from doc
            where doc.id = new.live_room_id and doc.doctype_alias = 'room');

    new.citizen_room_id         = new.live_room_id;
    new.citizen_room_head       =
        (select doc.head from doc
            where doc.id = new.citizen_room_id and doc.doctype_alias = 'room');


    new.live_roomtype_alias   = 'noobs';
    new.live_roomtype_id      =
        (select id from roomtype where roomtype.alias = new.live_roomtype_alias);

    new.invistype_alias   = 'visible';
    new.invistype_id      =
        (select id from invistype where invistype.alias = new.invistype_alias);
    new.invistype_level      =
        (select level from invistype where invistype.alias = new.invistype_alias);


    /**
        Положение пользователя в стране
    **/
    if (new.live_room_pos  is null) then
        new.live_room_pos = cast(
            cast (new.live_room_id as varchar(1024))
            || '.'
            ||  cast ((
                    select count(id)
                    from pers
                    where pers.live_room_id = new.live_room_id
                ) as varchar(1024)
            ) as numeric
        );
    end if;

    if not (new.geo_id is null) then
        update geo set
            nchildtargets   = nchildtargets + 1
        where
            geo.id = new.geo_id;
    end if;


    if (new.get_message_acctype_alias is null) then
        if not (new.get_message_acctype_id is null) then
            new.get_message_acctype_alias =
                (select alias from acctype where id = new.get_message_acctype_id);
        else
            new.get_message_acctype_alias  = 'public';
        end if;
    end if;
    if (new.get_message_acctype_id is null) then
        new.get_message_acctype_id     =
            (select id from acctype   where alias = new.get_message_acctype_alias);
    end if;


    if (new.get_thingbuy_acctype_alias is null) then
        if not (new.get_thingbuy_acctype_id is null) then
            new.get_thingbuy_acctype_alias =
                (select alias from acctype where id = new.get_thingbuy_acctype_id);
        else
            new.get_thingbuy_acctype_alias  = 'public';
        end if;
    end if;
    if (new.get_thingbuy_acctype_id is null) then
        new.get_thingbuy_acctype_id     =
            (select id from acctype   where alias = new.get_thingbuy_acctype_alias);
    end if;

    if (new.show_money_acctype_alias is null) then
        if not (new.show_money_acctype_id is null) then
            new.show_money_acctype_alias =
                (select alias from acctype where id = new.show_money_acctype_id);
        else
            new.show_money_acctype_alias  = 'public';
        end if;
    end if;
    if (new.show_money_acctype_id is null) then
        new.show_money_acctype_id     =
            (select id from acctype   where alias = new.show_money_acctype_alias);
    end if;


    return new;
end;
$$ language plpgsql;

/**
    Тригер начального состояния пользователя
**/
drop trigger if exists t1pers_util_fields_on_insert on pers ;
create trigger t1pers_util_fields_on_insert before insert
on pers for each row execute procedure pers_util_fields_on_insert();

/**
    @doc Обеспечивает совместное состояние пользователя
**/

create or replace function pers_util_fields_on_update() returns "trigger" as $$
begin
    if new.own_room_id != old.own_room_id then
        new.own_room_head =
            (select doc.head from doc
                where doc.id = new.own_room_id
                    and doc.doctype_alias = 'room');
    end if;
    if new.own_community_id != old.own_community_id then
        new.own_community_head =
            (select doc.head from doc
                where doc.id = new.own_community_id
                    and doc.doctype_alias = 'community');
    end if;
    if new.live_room_id != old.live_room_id then
        new.live_room_head =
            (select doc.head from doc
                where doc.id = new.live_room_id);
        new.live_roomtype_id =
            (select room.roomtype_id from room
                where room.doc_id = new.live_room_id);
        new.live_roomtype_alias =
            (select room.roomtype_alias from room
                where room.doc_id = new.live_room_id);
    end if;
    if (new.citizen_room_id != old.citizen_room_id) then
        new.citizen_room_head =
            (select doc.head from doc
                where doc.id = new.citizen_room_id);
        new.citizen_room_fromdatetime = utcnow();
        new.ostatus_alias = 'citizen';
        new.ostatus_id =
            (select id from ostatus   where alias = new.ostatus_alias);

    else
        if new.ostatus_id != old.ostatus_id then
            new.ostatus_alias =
                (select ostatus.alias
                    from ostatus
                        where ostatus.id = new.ostatus_id);
        end if;
        if new.ostatus_alias != old.ostatus_alias then
            new.ostatus_id =
                (select ostatus.id
                    from ostatus
                        where ostatus.alias = new.ostatus_alias);
        end if;
    end if;
    if (old.live_community_id is distinct from new.live_community_id) then
        if ((old.live_community_id is not null) and (new.live_community_id is not null)) then
            if (new.live_community_id != old.live_community_id) then
                raise exception 'exists_live_community';
            end if;
        end if;
        if ((old.live_community_id is null) and (new.live_community_id is not null)) then
            if (old.live_community_approved is null) and (new.live_community_approved is null) then
                update community set ncands = ncands + 1
                    where community.doc_id = new.live_community_id;
            end if;
            if (old.live_community_approved is null) and (new.live_community_approved = true) then
                update community set ncands = ncands - 1
                    where community.doc_id = new.live_community_id and ncands > 0;
                update community set nmembs = nmembs + 1
                    where community.doc_id = new.live_community_id;
            end if;
            if (old.live_community_approved is null) and (new.live_community_approved = false) then
                raise exception 'not_valid_combination';
            end if;
            if (old.live_community_approved = true ) and (new.live_community_approved = false) then
                raise exception 'not_valid_combination';
            end if;
            if (old.live_community_approved = true ) and (new.live_community_approved is null) then
                raise exception 'not_valid_combination';
            end if;
        end if;

        if ((old.live_community_id is not null) and (new.live_community_id is null)) then
            if (old.live_community_approved is null) then
                update community set ncands = ncands - 1
                    where community.doc_id = old.live_community_id and ncands > 0;
                new.live_community_id = null;
                new.live_community_approved = null;
            end if;
            if (old.live_community_approved = true) then
                update community set nmembs = nmembs - 1
                    where community.doc_id = old.live_community_id and nmembs > 0;
                new.live_community_id = null;
                new.live_community_approved = null;
            end if;
        end if;
    else
        if (old.live_community_approved is null) and (new.live_community_approved = true) then
            update community set ncands = ncands - 1
                where community.doc_id = new.live_community_id and ncands > 0;
            update community set nmembs = nmembs + 1
                where community.doc_id = new.live_community_id;
        end if;
        if (old.live_community_approved is null) and (new.live_community_approved = false) then
            update community set ncands = ncands - 1
                where community.doc_id = new.live_community_id and ncands > 0;
            new.live_community_id = null;
            new.live_community_approved = null;
        end if;
        if (old.live_community_approved = true ) and (new.live_community_approved = false) then
            update community set nmembs = nmembs - 1
                where community.doc_id = new.live_community_id and nmembs > 0;
            new.live_community_id = null;
            new.live_community_approved = null;
        end if;
        if (old.live_community_approved = true ) and (new.live_community_approved is null) then
            raise exception 'not_valid_combination';
        end if;
    end if;
    /**
        Статус online \ offline
    **/
    if new.pstatus_id != old.pstatus_id then
        new.pstatus_alias =
            (select pstatus.alias
                from pstatus
                    where pstatus.id = new.pstatus_id);
    end if;
    if new.pstatus_alias != old.pstatus_alias then
        new.pstatus_id =
            (select pstatus.id
                from pstatus
                    where pstatus.alias = new.pstatus_alias);
    end if;
    if new.exper != old.exper then
        /**
            Авторитет пользователя,
            Перевычисляем каждый раз
            на основе его опыта.
        **/
        new.authority_alias =
            (   select
                    alias
                from
                    authority
                where
                    level
                in (    select
                            max(level)
                        from
                            authority
                        where
                            level <= new.exper
                )
            );
        /**
            Сколько еще нужно опыта
            для перехода на следующий уровень.
        **/
        new.experlack    =
            (   select
                    min(cur.level)
                from
                    authority as cur
                join
                    authority as prev
                on
                    prev.level < cur.level
                where
                    prev.alias = new.authority_alias
            ) - new.exper;
    end if;

    if not (new.experlack is null) then
        new.experlackprice  = 0.5 * new.experlack;
    else
        new.experlackprice  = null;
    end if;
    /**
        Авторитет пользователя
    **/
    if new.live_roomtype_id != old.live_roomtype_id then
        new.live_roomtype_alias =
            (select roomtype.alias
                from
                    roomtype
                where
                    roomtype.id = new.live_roomtype_id);
    end if;
    if new.live_roomtype_alias != old.live_roomtype_alias then
        new.live_roomtype_id =
            (select roomtype.id
                from
                    roomtype
                where
                    roomtype.alias = new.live_roomtype_alias);
    end if;
    /**
        Авторитет пользователя
    **/
    if new.authority_id != old.authority_id then
        new.authority_alias =
            (select authority.alias
                from
                    authority
                where
                    authority.id = new.authority_id);
        new.authority_level =
            (select authority.level
                from
                    authority
                where
                    authority.id = new.authority_id);
    end if;
    if new.authority_alias != old.authority_alias then
        new.authority_id =
            (select authority.id
                from
                    authority
                where
                    authority.alias = new.authority_alias);
        new.authority_level =
            (select authority.level
                from
                    authority
                where
                    authority.alias = new.authority_alias);
    end if;
    /**
        Эмоции пользователя
    **/
    if new.emotion_id != old.emotion_id then
        new.emotion_alias =
            (select emotion.alias
                from
                    emotion
                where
                    emotion.id = new.emotion_id);
    end if;
    if new.emotion_alias != old.emotion_alias then
        new.emotion_id =
            (select emotion.id
                from
                    emotion
                where
                    emotion.alias = new.emotion_alias);
    end if;
    /**
        Семейное положения пользователя
    **/
    if new.mstatus_id != old.mstatus_id then
        new.mstatus_alias =
            (select mstatus.alias
                from
                    mstatus
                where
                    mstatus.id = new.mstatus_id
            );
    end if;
    if new.mstatus_alias != old.mstatus_alias then
        new.mstatus_id =
            (select mstatus.id
                from
                    mstatus
                where
                    mstatus.alias = new.mstatus_alias
            );
    end if;
    /**
        Язык пользователя
    **/
    if new.lang_id != old.lang_id then
        new.lang_alias =
            (select lang.alias
                from
                    lang
                where
                    lang.id = new.lang_id);
    end if;
    if new.lang_alias != old.lang_alias then
        new.lang_id =
            (select lang.id
                from
                    lang
                where
                    lang.alias = new.lang_alias);
    end if;


    /**
        Видимость пользователя
    **/
    if (
        (new.invistype_id != old.invistype_id)
        or (old.invistype_id is null)
        or (old.invistype_alias is null)
    ) then
        new.invistype_alias =
            (select invistype.alias
                from
                    invistype
                where
                    invistype.id = new.invistype_id);
        new.invistype_level =
            (select invistype.level
                from
                    invistype
                where
                    invistype.id = new.invistype_id);
    end if;
    if (
        (new.invistype_alias != old.invistype_alias)
        or (new.invistype_id is null)
        or (new.invistype_alias is null)
    ) then
        new.invistype_id =
            (select invistype.id
                from
                    invistype
                where
                    invistype.alias = new.invistype_alias);
        new.invistype_level =
            (select invistype.level
                from
                    invistype
                where
                    invistype.id = new.invistype_id);
    end if;

    if new.live_room_pos != old.live_room_pos then
        if (new.live_room_pos  is null) then
            new.live_room_pos = cast(
                cast (new.live_room_id as varchar(1024))
                || '.'
                ||  cast ((
                        select count(id)
                        from pers
                        where pers.live_room_id = new.live_room_id
                    ) as varchar(1024)
                ) as numeric
            );
        end if;
    end if;

    if new.geo_id != old.geo_id then
        update geo set
            nchildtargets   = nchildtargets + 1
        where
            geo.id = new.geo_id;
        update geo set
            nchildtargets   = nchildtargets - 1
        where
            geo.id = new.geo_id;
    end if;
    if (new.isdeleted = true) and (old.isdeleted = false) then
        update geo set
            nchildtargets   = nchildtargets - 1
        where
            geo.id = new.geo_id;
    end if;
    if (new.isdeleted = false) and (old.isdeleted = true) then
        update geo set
            nchildtargets   = nchildtargets + 1
        where
            geo.id = new.geo_id;
    end if;


    if new.get_message_acctype_id != old.get_message_acctype_id then
        new.get_message_acctype_alias =
            (select acctype.alias
                from
                    acctype
                where
                    acctype.id = new.get_message_acctype_id);
    end if;
    if new.get_message_acctype_alias != old.get_message_acctype_alias then
        new.get_message_acctype_id =
            (select acctype.id
                from
                    acctype
                where
                    acctype.alias = new.get_message_acctype_alias);
    end if;

    if new.get_thingbuy_acctype_id != old.get_thingbuy_acctype_id then
        new.get_thingbuy_acctype_alias =
            (select acctype.alias
                from
                    acctype
                where
                    acctype.id = new.get_thingbuy_acctype_id);
    end if;
    if new.get_thingbuy_acctype_alias != old.get_thingbuy_acctype_alias then
        new.get_thingbuy_acctype_id =
            (select acctype.id
                from
                    acctype
                where
                    acctype.alias = new.get_thingbuy_acctype_alias);
    end if;


    if new.show_money_acctype_id != old.show_money_acctype_id then
        new.show_money_acctype_alias =
            (select acctype.alias
                from
                    acctype
                where
                    acctype.id = new.show_money_acctype_id);
    end if;
    if new.show_money_acctype_alias != old.show_money_acctype_alias then
        new.show_money_acctype_id =
            (select acctype.id
                from
                    acctype
                where
                    acctype.alias = new.show_money_acctype_alias);
    end if;


    return new;
end;
$$ language plpgsql;

drop trigger if exists t1pers_util_fields_on_update on pers ;
create trigger t1pers_util_fields_on_update before update
on pers for each row execute procedure pers_util_fields_on_update();

create or replace function pers_util_fields_on_delete() returns "trigger" as $$
begin
    if not (old.geo_id is null) then
        update geo set
            nchildtargets   = nchildtargets - 1
        where
            geo.id = old.geo_id;
    end if;
    return old;
end;
$$ language plpgsql;


drop trigger if exists t1pers_util_fields_on_delete on pers ;
create trigger t1pers_util_fields_on_delete before delete
on pers for each row execute procedure pers_util_fields_on_delete();



\echo :FILE ok
