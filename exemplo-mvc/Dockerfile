FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src
COPY AulaMvc.csproj ./
RUN dotnet restore AulaMvc.csproj
COPY . ./
RUN dotnet publish AulaMvc.csproj -c Release -o /out --no-restore

FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS final
WORKDIR /app
COPY --from=build /out ./
ENV ASPNETCORE_HTTP_PORTS=8080
USER app
EXPOSE 8080
ENTRYPOINT ["dotnet", "AulaMvc.dll"]
