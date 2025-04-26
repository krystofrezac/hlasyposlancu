defmodule App.ParliamentTest do
  use App.DataCase

  alias App.Parliament

  describe "person" do
    alias App.Parliament.Person

    import App.ParliamentFixtures

    @invalid_attrs %{
      before_title: nil,
      first_name: nil,
      last_name: nil,
      after_title: nil,
      birth_date: nil,
      sex: nil,
      updated_at: nil,
      died_at: nil
    }

    test "list_person/0 returns all person" do
      person = person_fixture()
      assert Parliament.list_person() == [person]
    end

    test "get_person!/1 returns the person with given id" do
      person = person_fixture()
      assert Parliament.get_person!(person.id) == person
    end

    test "create_person/1 with valid data creates a person" do
      valid_attrs = %{
        before_title: "some before_title",
        first_name: "some first_name",
        last_name: "some last_name",
        after_title: "some after_title",
        birth_date: ~U[2025-04-25 07:22:00Z],
        sex: :male,
        updated_at: ~U[2025-04-25 07:22:00Z],
        died_at: ~U[2025-04-25 07:22:00Z]
      }

      assert {:ok, %Person{} = person} = Parliament.create_person(valid_attrs)
      assert person.before_title == "some before_title"
      assert person.first_name == "some first_name"
      assert person.last_name == "some last_name"
      assert person.after_title == "some after_title"
      assert person.birth_date == ~U[2025-04-25 07:22:00Z]
      assert person.sex == :male
      assert person.updated_at == ~U[2025-04-25 07:22:00Z]
      assert person.died_at == ~U[2025-04-25 07:22:00Z]
    end

    test "create_person/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Parliament.create_person(@invalid_attrs)
    end

    test "update_person/2 with valid data updates the person" do
      person = person_fixture()

      update_attrs = %{
        before_title: "some updated before_title",
        first_name: "some updated first_name",
        last_name: "some updated last_name",
        after_title: "some updated after_title",
        birth_date: ~U[2025-04-26 07:22:00Z],
        sex: :female,
        updated_at: ~U[2025-04-26 07:22:00Z],
        died_at: ~U[2025-04-26 07:22:00Z]
      }

      assert {:ok, %Person{} = person} = Parliament.update_person(person, update_attrs)
      assert person.before_title == "some updated before_title"
      assert person.first_name == "some updated first_name"
      assert person.last_name == "some updated last_name"
      assert person.after_title == "some updated after_title"
      assert person.birth_date == ~U[2025-04-26 07:22:00Z]
      assert person.sex == :female
      assert person.updated_at == ~U[2025-04-26 07:22:00Z]
      assert person.died_at == ~U[2025-04-26 07:22:00Z]
    end

    test "update_person/2 with invalid data returns error changeset" do
      person = person_fixture()
      assert {:error, %Ecto.Changeset{}} = Parliament.update_person(person, @invalid_attrs)
      assert person == Parliament.get_person!(person.id)
    end

    test "delete_person/1 deletes the person" do
      person = person_fixture()
      assert {:ok, %Person{}} = Parliament.delete_person(person)
      assert_raise Ecto.NoResultsError, fn -> Parliament.get_person!(person.id) end
    end

    test "change_person/1 returns a person changeset" do
      person = person_fixture()
      assert %Ecto.Changeset{} = Parliament.change_person(person)
    end
  end

  describe "deputy" do
    alias App.Parliament.Deputy

    import App.ParliamentFixtures

    @invalid_attrs %{person_id: nil}

    test "list_deputy/0 returns all deputy" do
      deputy = deputy_fixture()
      assert Parliament.list_deputy() == [deputy]
    end

    test "get_deputy!/1 returns the deputy with given id" do
      deputy = deputy_fixture()
      assert Parliament.get_deputy!(deputy.id) == deputy
    end

    test "create_deputy/1 with valid data creates a deputy" do
      valid_attrs = %{person_id: 42}

      assert {:ok, %Deputy{} = deputy} = Parliament.create_deputy(valid_attrs)
      assert deputy.person_id == 42
    end

    test "create_deputy/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Parliament.create_deputy(@invalid_attrs)
    end

    test "update_deputy/2 with valid data updates the deputy" do
      deputy = deputy_fixture()
      update_attrs = %{person_id: 43}

      assert {:ok, %Deputy{} = deputy} = Parliament.update_deputy(deputy, update_attrs)
      assert deputy.person_id == 43
    end

    test "update_deputy/2 with invalid data returns error changeset" do
      deputy = deputy_fixture()
      assert {:error, %Ecto.Changeset{}} = Parliament.update_deputy(deputy, @invalid_attrs)
      assert deputy == Parliament.get_deputy!(deputy.id)
    end

    test "delete_deputy/1 deletes the deputy" do
      deputy = deputy_fixture()
      assert {:ok, %Deputy{}} = Parliament.delete_deputy(deputy)
      assert_raise Ecto.NoResultsError, fn -> Parliament.get_deputy!(deputy.id) end
    end

    test "change_deputy/1 returns a deputy changeset" do
      deputy = deputy_fixture()
      assert %Ecto.Changeset{} = Parliament.change_deputy(deputy)
    end
  end

  describe "body" do
    alias App.Parliament.Body

    import App.ParliamentFixtures

    @invalid_attrs %{name: nil, to: nil, from: nil, abbreviation: nil}

    test "list_body/0 returns all body" do
      body = body_fixture()
      assert Parliament.list_body() == [body]
    end

    test "get_body!/1 returns the body with given id" do
      body = body_fixture()
      assert Parliament.get_body!(body.id) == body
    end

    test "create_body/1 with valid data creates a body" do
      valid_attrs = %{
        name: "some name",
        to: ~D[2025-04-25],
        from: ~D[2025-04-25],
        abbreviation: "some abbreviation"
      }

      assert {:ok, %Body{} = body} = Parliament.create_body(valid_attrs)
      assert body.name == "some name"
      assert body.to == ~D[2025-04-25]
      assert body.from == ~D[2025-04-25]
      assert body.abbreviation == "some abbreviation"
    end

    test "create_body/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Parliament.create_body(@invalid_attrs)
    end

    test "update_body/2 with valid data updates the body" do
      body = body_fixture()

      update_attrs = %{
        name: "some updated name",
        to: ~D[2025-04-26],
        from: ~D[2025-04-26],
        abbreviation: "some updated abbreviation"
      }

      assert {:ok, %Body{} = body} = Parliament.update_body(body, update_attrs)
      assert body.name == "some updated name"
      assert body.to == ~D[2025-04-26]
      assert body.from == ~D[2025-04-26]
      assert body.abbreviation == "some updated abbreviation"
    end

    test "update_body/2 with invalid data returns error changeset" do
      body = body_fixture()
      assert {:error, %Ecto.Changeset{}} = Parliament.update_body(body, @invalid_attrs)
      assert body == Parliament.get_body!(body.id)
    end

    test "delete_body/1 deletes the body" do
      body = body_fixture()
      assert {:ok, %Body{}} = Parliament.delete_body(body)
      assert_raise Ecto.NoResultsError, fn -> Parliament.get_body!(body.id) end
    end

    test "change_body/1 returns a body changeset" do
      body = body_fixture()
      assert %Ecto.Changeset{} = Parliament.change_body(body)
    end
  end
end
