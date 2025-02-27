# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#     http://www.apache.org/licenses/LICENSE-2.0
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
defmodule Schema.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @spec start(any, any) :: {:error, any} | {:ok, pid}
  def start(_type, _args) do
    extension =
      case Application.get_env(:schema_server, __MODULE__) |> Keyword.get(:extension) do
        nil -> []
        ext -> String.split(ext, ",")
      end

    schemas_dir =
      case Application.get_env(:schema_server, __MODULE__) do
        nil -> nil
        env -> Keyword.get(env, :schema_home)
      end

    # List all child processes to be supervised
    children = [
      {Schemas, schemas_dir},
      {Schema.JsonReader, extension},
      Schema.Repo,
      Schema.Generator,

      # Start the endpoint when the application starts
      SchemaWeb.Endpoint,
      {Phoenix.PubSub, [name: Schema.PubSub, adapter: Phoenix.PubSub.PG2]}
    ]

    # initialize the example links
    Schema.Examples.init_cache()

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Schema.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    SchemaWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
